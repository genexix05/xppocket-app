FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY html /usr/share/nginx/html
EXPOSE 8081
CMD ["nginx", "-g", "daemon off;"]
