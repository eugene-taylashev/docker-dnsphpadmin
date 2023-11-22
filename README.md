# docker-dnsphpadmin
This project is to wrap the [dnsphpadmin](https://github.com/benapetr/dnsphpadmin) tool into a Docker image.

Apache's ``httpd.conf`` and DNSphpAdmin's ``config.php`` files could be located in a mounted volume for persistent configuration:
```
docker run -d \
  --name dnsadmin \
  -p 8080:80/tcp \
  -v ./my-conf:/etc/dnsphpadmin \
  -e VERBOSE=${VERBOSE} \
etaylashev/dnsphpadmin:${ARCH}latest
```
