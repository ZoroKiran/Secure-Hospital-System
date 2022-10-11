package com.aws.listener.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.aws.listener.repo.SqsRepo;
import com.aws.listener.repo.SqsRepoImpl;
import com.aws.listener.service.ListenerAndDispatchingService;
import com.aws.listener.service.ListenerAndDispatchingServiceImpl;
import com.aws.listener.service.SqsService;
import com.aws.listener.service.SqsServiceImpl;

@Configuration
public class AppConfig {

	@Bean
	public ListenerAndDispatchingService listenerAndDispatchingService() {
		return new ListenerAndDispatchingServiceImpl();
	}

	@Bean
	public SqsService sqsService() {
		return new SqsServiceImpl();
	}

	@Bean
	public SqsRepo sqsRepo() {
		return new SqsRepoImpl();
	}


	@Bean
	public AwsConfiguration awsConfiguration() {
		return new AwsConfiguration();
	}

}
