files=`find /usr/local/srs/objs/nginx/html/ -type f -mtime +7`
echo "$(date)-----M3u8 Cleaning Script is running!">>/usr/local/srs/objs/nginx/M3u8_clear.log
for file in ${files[@]}
do
  file_data=`ls -lt $file`
  echo "  $(date)-----${file_data} , File storage time more than 7 day , has been deleted!">>/usr/local/srs/objs/nginx/M3u8_clear.log
done
echo -e "\n">>/usr/local/srs/objs/nginx/M3u8_clear.log
find /usr/local/srs/objs/nginx/html/ -type f -mtime +7 -delete
