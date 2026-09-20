FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/

# Change the default Nginx port from 80 to 3000
RUN sed -i 's/\(listen.*\)80;/\13000;/' /etc/nginx/conf.d/default.conf

EXPOSE 3000