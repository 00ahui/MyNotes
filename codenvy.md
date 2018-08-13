### Build

Maven build without test

```shell
mvn clean install -f ${current.project.path} -Dmaven.test.skip=true
```

### Run

Java run

```shell
java -classpath ${project.java.classpath}${project.java.output.dir} ${current.class.fqn}
```




