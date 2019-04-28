find /usr/local/srs/objs/nginx/html/ -type f -mtime +7 -delete
echo "$(date)-----M3u8 Cleaning Script is running!">>/usr/local/srs/objs/nginx/html/M3u8_clear.log
