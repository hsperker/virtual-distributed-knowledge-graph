FROM openjdk:8-jdk-alpine
COPY ./uni-sample /opt/h2
EXPOSE 8082
EXPOSE 9082
CMD ["java", "-cp", "/opt/h2/bin/h2-1.4.196.jar", "org.h2.tools.Server", "-tcpAllowOthers",  "-webAllowOthers" ]