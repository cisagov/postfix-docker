#!/usr/bin/env pytest -vs
"""Tests for postfix container."""

# Standard Python Libraries
from email.message import EmailMessage
from imaplib import IMAP4_SSL
import os
import smtplib
import time

# Third-Party Libraries
import pytest

ARCHIVE_PW = "foobar"
ARCHIVE_USER = "mailarchive"
DOMAIN = "example.com"
IMAP_PORT = 1993
MESSAGE = """
This is a test message sent during the unit tests.
"""
READY_MESSAGE = "daemon started"
RELEASE_TAG = os.getenv("RELEASE_TAG")
TEST_SEND_PW = "lemmy is god"
TEST_SEND_USER = "testsender1"
VERSION_FILE = "src/version.txt"


def test_container_count(dockerc):
    """Verify the test composition and container."""
    # all parameter allows non-running containers in results
    assert (
        len(dockerc.compose.ps(all=True)) == 1
    ), "Wrong number of containers were started."


def test_wait_for_ready(main_container):
    """Wait for container to be ready."""
    TIMEOUT = 10
    for i in range(TIMEOUT):
        if READY_MESSAGE in main_container.logs():
            break
        time.sleep(1)
    else:
        raise Exception(
            f"Container does not seem ready.  "
            f'Expected "{READY_MESSAGE}" in the log within {TIMEOUT} seconds.'
        )


@pytest.mark.parametrize("port", [1025, 1587])
@pytest.mark.parametrize("to_user", [ARCHIVE_USER, TEST_SEND_USER])
def test_sending_mail(port, to_user):
    """Send an email message to the server."""
    msg = EmailMessage()
    msg.set_content(MESSAGE)
    msg["Subject"] = f"Test Message on port {port}"
    msg["From"] = f"test@{DOMAIN}"
    msg["To"] = f"{to_user}@{DOMAIN}"
    with smtplib.SMTP("localhost", port=port) as s:
        s.send_message(msg)


@pytest.mark.parametrize(
    "username,password",
    [
        (ARCHIVE_USER, ARCHIVE_PW),
        (TEST_SEND_USER, TEST_SEND_PW),
        pytest.param(ARCHIVE_USER, TEST_SEND_PW, marks=pytest.mark.xfail),
        pytest.param("your_mom", "so_fat", marks=pytest.mark.xfail),
    ],
)
def test_imap_login(username, password):
    """Test logging in to the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)


# Note that "username" is changed to "user" in this function to work around
# a CodeQL failure for "Clear-text logging of sensitive information". :(
@pytest.mark.parametrize(
    "user,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_messages_exist(user, password):
    """Test test existence of our test messages."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(user, password)
        typ, data = m.select()
        assert typ == "OK", f"Select did not return OK status for {user}"
        message_count = int(data[0])
        print(f"{user} inbox message count: {message_count}")
        assert message_count > 0, f"Expected message in the {user} inbox"


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_reading(username, password):
    """Test receiving message from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        typ, data = m.search(None, "ALL")
        assert typ == "OK", "Search did not return OK status"
        message_numbers = data[0].split()
        for num in message_numbers:
            typ, data = m.fetch(num, "(RFC822)")
            assert typ == "OK", f"Fetch of message {num} did not return OK status"
            print("-" * 40)
            print(f"Message: {num}")
            print(data[0][1].decode("utf-8"))
            # mark messag as deleted
            typ, data = m.store(num, "+FLAGS", "\\Deleted")
            assert (
                typ == "OK"
            ), f"Storing '\\deleted' flag on message {num} did not return OK status"
        # expunge all deleted messages
        typ, data = m.expunge()
        assert typ == "OK", "Expunge did not return OK status"


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_delete_all(username, password):
    """Test deleting messages from the IMAP server."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        typ, data = m.search(None, "ALL")
        assert typ == "OK", "Search did not return OK status"
        message_numbers = data[0].split()
        for num in message_numbers:
            # mark messag as deleted
            typ, data = m.store(num, "+FLAGS", "\\Deleted")
            assert (
                typ == "OK"
            ), f"Storing '\\deleted' flag on message {num} did not return OK status"
        # expunge all deleted messages
        typ, data = m.expunge()
        assert typ == "OK", "Expunge did not return OK status"


@pytest.mark.parametrize(
    "username,password", [(ARCHIVE_USER, ARCHIVE_PW), (TEST_SEND_USER, TEST_SEND_PW)]
)
def test_imap_messages_cleared(username, password):
    """Test that all messages were expunged."""
    with IMAP4_SSL("localhost", IMAP_PORT) as m:
        m.login(username, password)
        typ, data = m.select()
        assert typ == "OK", "Select did not return OK status"
        message_count = int(data[0])
        print(f"inbox message count: {message_count}")
        assert message_count == 0, "Expected the inbox to be empty"


@pytest.mark.skipif(
    RELEASE_TAG in [None, ""], reason="this is not a release (RELEASE_TAG not set)"
)
def test_release_version():
    """Verify that release tag version agrees with the module version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        RELEASE_TAG == f"v{project_version}"
    ), "RELEASE_TAG does not match the project version"


def test_container_version_label_matches(main_container):
    """Verify the container version label is the correct version."""
    pkg_vars = {}
    with open(VERSION_FILE) as f:
        exec(f.read(), pkg_vars)  # nosec
    project_version = pkg_vars["__version__"]
    assert (
        main_container.config.labels["org.opencontainers.image.version"]
        == project_version
    ), "Dockerfile version label does not match project version"
