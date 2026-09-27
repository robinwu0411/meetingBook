package com.example.meetingbook.config;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@MapperScan("com.example.meetingbook.infrastructure.mapper")
public class MyBatisConfig {}
