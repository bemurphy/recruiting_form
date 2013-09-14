# Unnamed Recruiter form

A tiny Sinatra app, useful in the context of Meetups to point recruiters or employers to.

The app simply presents a basic form to collect basic information about a job opportunity.  Once
filled out by a recruiter, it will generate an email copy of the posting to admins of the system.

Admins will then have the option to approve the posting by clicking on a link in the email, which
will trigger an email generated to the Meetup list.

Essentially, the app acts as an approval proxy of sorts, to give people a place to go, as well
as postings to the Meetup as slightly increased air of authenticity.

## Installation

Clone the app and push to Heroku.

The app makes heavy use of ENV config:

```shell
DB_URL # A CouchDB/Cloudant URL for storing the posting in

MAIL_FROM # The email address to send from

LIST_ADDRESS # The Meetup list email to forward approved postings to

MALONE_URL # URL for the smtp server

APP_HOST # Host/port (if applicable) for email url use

ADMIN_EMAILS # Admin emails, comma delimited
```

## Notes

The system is fairly dumb.  It simply takes postings, tosses into CouchDB,
because it's easy, big, and free.  No real user accounts exists, as the
approval process is performed entirely by email.  This is easier than
having to login anyway.

## Todos

- Setup a disposable email address in the system using a token, wired email
replies via MailGun or SendGrid parse API to be redirected to this address.
- Set reply-to/from of meetup notification messages to the disposable email
