#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" == "--help" ]]; then
  cat <<'HELP'
Usage: bash create-ddd-project.sh TARGET_DIR [BASE_PACKAGE] 
Example: bash create-ddd-project.sh ./meeting-room com.example.meetingroom
Requires Python 3 to generate files; Java 17+ and Maven to build/run.
Creates a single-module Spring Boot project. Allows empty directories or directories containing only Git/Claude setup files.
When bundled in a skill, copies its SKILL.md and references into the new project.
Copies current working directory CLAUDE.md first, falling back to bundled rules.
Includes Swagger UI, Dockerfile, docker-compose.yml and a local Git repository.
Automatically resolves latest stable Spring Boot and compatible MyBatis starter from Maven Central.
HELP
  exit 0
fi
if [[ $# -eq 0 ]]; then
  read -r -p '项目路径 [当前目录 .]: ' target || exit 1
  read -r -p 'Java 根包 [com.example.demo]: ' package_name || exit 1
  set -- "${target:-.}" "${package_name:-com.example.demo}"
fi
[[ $# -le 2 ]] || { echo 'Too many arguments' >&2; exit 2; }
command -v python3 >/dev/null || { echo 'Python 3 is required' >&2; exit 1; }
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
python3 - "$1" "${2:-com.example.demo}" "auto" "$script_dir" <<'PY'
import sys, re, shutil, subprocess, urllib.request, xml.etree.ElementTree as ET
from pathlib import Path
from xml.sax.saxutils import escape
if not shutil.which('git'): sys.exit('Git is required; no project files created.')
invocation_dir=Path.cwd()
out=Path(sys.argv[1]).expanduser().resolve()
pkg,boot=sys.argv[2:4]
source=Path(sys.argv[4])
if not re.fullmatch(r'[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+',pkg):
    sys.exit('Invalid Java base package')
keywords=set('abstract assert boolean break byte case catch char class const continue default do double else enum extends final finally float for goto if implements import instanceof int interface long native new package private protected public return short static strictfp super switch synchronized this throw throws transient try void volatile while true false null _'.split())
if any(x in keywords for x in pkg.split('.')): sys.exit('Package contains Java keyword')
def latest_stable(path, major=None):
    url='https://repo.maven.apache.org/maven2/'+path+'/maven-metadata.xml'
    try:
        with urllib.request.urlopen(url, timeout=20) as response:
            root=ET.fromstring(response.read())
        versions=[v.text for v in root.findall('./versioning/versions/version') if v.text and re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+',v.text)]
        if major is not None: versions=[v for v in versions if v.split('.')[0]==str(major)]
        return max(versions,key=lambda v: tuple(map(int,v.split('.'))))
    except Exception as e: sys.exit('Cannot resolve latest stable dependency: '+url+' ('+str(e)+'). No project files created.')
boot=latest_stable('org/springframework/boot/spring-boot-starter-parent')
boot_major=int(boot.split('.')[0])
if boot_major not in (3,4): sys.exit('Latest Boot major is not supported by this scaffold; no files created.')
mybatis=latest_stable('org/mybatis/spring/boot/mybatis-spring-boot-starter',boot_major)
springdoc=latest_stable('org/springdoc/springdoc-openapi-starter-webmvc-ui',boot_major-1)
print('Resolved Spring Boot '+boot+' / MyBatis starter '+mybatis+' / springdoc '+springdoc)
artifact=out.name
if not re.fullmatch(r'[a-z][a-z0-9-]*',artifact): sys.exit('Target folder name must be lowercase letters, digits and hyphens, starting with a letter')
if out.exists():
    if not out.is_dir(): sys.exit('Target is not a directory')
    allowed = {'.git', '.gitignore', '.claude', 'CLAUDE.md', '.DS_Store'}
    extra = [p.name for p in out.iterdir() if p.name not in allowed]
    if extra: sys.exit('Refusing existing project/files: '+', '.join(extra))
out.mkdir(parents=True,exist_ok=True)
def write(name,text):
    p=out/name
    if p.exists() or p.is_symlink():
        if name == '.gitignore': return
        raise SystemExit('Refusing to overwrite: '+str(p))
    p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
base='src/main/java/'+pkg.replace('.','/')
packages=['controller','service','service/impl','domain','repository','infrastructure/repository','infrastructure/mapper','infrastructure/po','infrastructure/converter','converter','dto/request','dto/response','exception','config']
for sub in packages:
    write(base+'/'+sub+'/package-info.java','/** Project package; add only classes required by confirmed use cases. */\npackage '+pkg+'.'+sub.replace('/','.')+';\n')
write('pom.xml',f'''<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-parent</artifactId><version>{boot}</version><relativePath/></parent>
  <groupId>{pkg}</groupId><artifactId>{artifact}</artifactId><version>0.0.1-SNAPSHOT</version>
  <properties><java.version>17</java.version><mapstruct.version>1.6.3</mapstruct.version><mybatis.version>{mybatis}</mybatis.version></properties>
  <dependencies>
    <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>{springdoc}</version></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
    <dependency><groupId>org.mybatis.spring.boot</groupId><artifactId>mybatis-spring-boot-starter</artifactId><version>${{mybatis.version}}</version></dependency>
    <dependency><groupId>com.mysql</groupId><artifactId>mysql-connector-j</artifactId><scope>runtime</scope></dependency>
    <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
    <dependency><groupId>org.mapstruct</groupId><artifactId>mapstruct</artifactId><version>${{mapstruct.version}}</version></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
  </dependencies>
  <build><plugins>
    <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
    <plugin><groupId>org.apache.maven.plugins</groupId><artifactId>maven-compiler-plugin</artifactId><configuration>
      <parameters>true</parameters>
      <annotationProcessorPaths>
        <path><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><version>${{lombok.version}}</version></path>
        <path><groupId>org.projectlombok</groupId><artifactId>lombok-mapstruct-binding</artifactId><version>0.2.0</version></path>
        <path><groupId>org.mapstruct</groupId><artifactId>mapstruct-processor</artifactId><version>${{mapstruct.version}}</version></path>
      </annotationProcessorPaths>
    </configuration></plugin>
  </plugins></build>
</project>
''')
write(base+'/Application.java',f'''package {pkg};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {{
    public static void main(String[] args) {{
        SpringApplication.run(Application.class, args);
    }}
}}
''')
write(base+'/config/MyBatisConfig.java',f'''package {pkg}.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("{pkg}.infrastructure.mapper")
public class MyBatisConfig {{}}
''')
write('src/main/resources/application.yml','''spring:
  datasource:
    url: ${DB_URL:jdbc:mysql://localhost:3306/app_db?serverTimezone=UTC}
    username: ${DB_USER:root}
    password: ${DB_PASSWORD:}
mybatis:
  mapper-locations: classpath*:mapper/**/*.xml
  configuration:
    map-underscore-to-camel-case: true
''')
write('Dockerfile','''FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /build/target/*.jar /app/app.jar
USER 10001:10001
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
''')
write('.dockerignore', 'target/\n.git/\n.idea/\n.env\n.claude/\nCLAUDE.md\n')
write('docker-compose.yml','''# Local development defaults; override passwords via environment variables.
services:
  app:
    build: .
    ports:
      - "127.0.0.1:${APP_PORT:-8080}:8080"
    environment:
      DB_URL: jdbc:mysql://mysql:3306/app_db?serverTimezone=UTC&allowPublicKeyRetrieval=true&useSSL=false
      DB_USER: app
      DB_PASSWORD: ${DB_PASSWORD:-local-dev-password}
    depends_on:
      mysql:
        condition: service_healthy
  mysql:
    image: mysql:8.4
    environment:
      MYSQL_DATABASE: app_db
      MYSQL_USER: app
      MYSQL_PASSWORD: ${DB_PASSWORD:-local-dev-password}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-local-root-password}
    volumes:
      - mysql-data:/var/lib/mysql
    healthcheck:
      test: ["CMD-SHELL", "MYSQL_PWD=$$MYSQL_PASSWORD mysql -h 127.0.0.1 -u app -D app_db -e 'SELECT 1'"]
      interval: 5s
      timeout: 5s
      retries: 30
      start_period: 30s
volumes:
  mysql-data:
''')
write('src/main/resources/mapper/.gitkeep','')
write('src/test/java/'+pkg.replace('.','/')+'/package-info.java','/** Add use-case tests after business rules are confirmed. */\npackage '+pkg+';\n')
write('.gitignore','target/\n.idea/\n*.iml\n.env\n.DS_Store\n')
skill = source.parent if source.name == 'scripts' and (source.parent/'SKILL.md').is_file() else source/'ddd-java'
rules = next((p for p in (invocation_dir/'CLAUDE.md', skill/'CLAUDE.md', source/'CLAUDE.md') if p.is_file()), skill/'CLAUDE.md')
if rules.is_file() and not (out/'CLAUDE.md').exists() and not (out/'CLAUDE.md').is_symlink(): shutil.copy2(rules,out/'CLAUDE.md')
if (skill/'SKILL.md').is_file() and not (out/'.claude/skills/ddd-java').exists() and not (out/'.claude').is_symlink() and not (out/'.claude/skills').is_symlink():
    dest = out/'.claude/skills/ddd-java'
    dest.mkdir(parents=True)
    shutil.copy2(skill/'SKILL.md',dest/'SKILL.md')
    for folder in ('references', 'scripts'):
        if (skill/folder).is_dir(): shutil.copytree(skill/folder,dest/folder)
review_installer = source/'install-review-controls.py'
if review_installer.is_file():
    subprocess.run([sys.executable, str(review_installer), str(out)], check=True)
else:
    print('Review installer missing; project review controls were not installed.')
if not (out/'.git').exists():
    subprocess.run(['git', 'init', '-b', 'main', str(out)], check=True)
print('Created: '+str(out))
print('Local Git repository ready; no staging, commits or remote configured.')
print('Container startup: docker compose up --build')
print('Swagger UI: http://localhost:8080/swagger-ui/index.html; OpenAPI: /v3/api-docs')
print('Next: configure DB_URL, DB_USER, DB_PASSWORD for an existing MySQL database.')
print('Then run in the project: mvn test; mvn spring-boot:run')
print('No domain behavior or business tests generated. No Maven wrapper or Git commits created.')
print('CLAUDE.md copied: '+str((out/'CLAUDE.md').exists()))
print('Modeling skill copied: '+str((out/'.claude/skills/ddd-java/SKILL.md').exists()))
PY
