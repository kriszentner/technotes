# Sample usage
docker run --rm -it -vC:\Users\$ENV:USERNAME\.ssh\id_rsa:/fabric/id_rsa fabric /bin/sh
#
# Run fabric
# docker run --rm -it -vC:\Users\$ENV:USERNAME\.ssh\id_rsa:/fabric/id_rsa fabric fab -w -R test hostname
