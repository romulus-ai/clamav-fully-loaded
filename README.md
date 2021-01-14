# clamav-fully-loaded

A full set of ClamAV, it includes Clamd, Freshclam to update the DBs hourly and also unofficial sigs to have a better detection rate!

Clamd listens at Port 3310.

Freshclam runs also as daemon in the container and update hourly.

Unofficial Sigs is also executed hourly via cronjob.