#ulib
# The Universal SCCP Libary 

ulibmtp3 is a implementation of the SS7 SCCP protocol
it makes extensive use of the universal library "ulib" and "ulibmtp3"
It works on Linux, FreeBSD and to some extent on MacOS (lacking SCTP support)

Under Linux and FreeBSD, GNUStep is used as an underlying framework.
Under MacOS Foundation is used.



# Related #

ulibsccp is the base class of a family of libraries and applications.

* **ulib**     a universal library 
* **ulibmtp3** a universal MTP3 library supporting M2PA and M3UA
* **ulibsccp** a library implementing the SS7 SCCP protocol
* **ulibtcap** a library implementing the SS7 TCAP protocol
* **ulibgsmmap** a library implementing the SS7 GSM-MAP protocol
* **ulibsms**  a library implementing SMS encoding/decoding functions
* **ulibsmpp** a library to deal with the SMPP protocol
* **ulibdns** a library doing DNS functionality
* **schrittmacherclient** a library for applications to implement a hot/standby mechanism
* **schrittmacher** a system daemon dealing with applications in a hot/standby setup, making sure there is always one system hot and one is standby.
* **messagemover** a application implementing a SS7 GSM-SMSC (commercial)
* **estp** a application implementing a SS7 packet router (enhanced signaling transfer point) (commercial)
* **smsproxy** a application implementing a HLR and MSC for receiving SMS on SS7 (commercial)
* **gsm-api** a application implementing a SS7 API Server for all kinds of lookups. (commercial)

# Merged functionalities #

Release 6.0 (2026) merged in some functionality which where previously in separately libraries

* **ulibgt**   global title handling functions
