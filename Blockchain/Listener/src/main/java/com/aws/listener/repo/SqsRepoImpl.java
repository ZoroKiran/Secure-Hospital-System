package com.aws.listener.repo;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.List;

import org.apache.commons.codec.binary.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Repository;

import com.amazonaws.services.sqs.model.CreateQueueResult;
import com.amazonaws.services.sqs.model.DeleteMessageRequest;
import com.amazonaws.services.sqs.model.Message;
import com.amazonaws.services.sqs.model.QueueDoesNotExistException;
import com.amazonaws.services.sqs.model.ReceiveMessageRequest;
import com.amazonaws.services.sqs.model.ReceiveMessageResult;
import com.amazonaws.services.sqs.model.SendMessageRequest;
import com.aws.listener.config.AwsConfiguration;

@Repository
public class SqsRepoImpl implements SqsRepo {

	private static final Logger LOGGER = LoggerFactory.getLogger(SqsRepoImpl.class);

	@Autowired
	private AwsConfiguration awsConfiguration;

	@Override
	public void deleteMessage(Message message, String queueName) {
		LOGGER.debug("Deleting the message in the queue.");
		String queueUrl = awsConfiguration.amazonSQS().getQueueUrl(queueName).getQueueUrl();
		String messageReceiptHandle = message.getReceiptHandle();
		DeleteMessageRequest deleteMessageRequest = new DeleteMessageRequest(queueUrl, messageReceiptHandle);
		awsConfiguration.amazonSQS().deleteMessage(deleteMessageRequest);
	}

	@Override
	public CreateQueueResult createQueue(String queueName) {
		LOGGER.debug("Creating the queue.");
		CreateQueueResult createQueueResult = awsConfiguration.amazonSQS().createQueue(queueName);
		return createQueueResult;
	}


	@Override
	public Message receiveMessage(String queueName, Integer waitTime, Integer visibilityTimeout) {
		LOGGER.debug("Receiving the message from the queue.");
		String queueUrl = awsConfiguration.amazonSQS().getQueueUrl(queueName).getQueueUrl();
		ReceiveMessageRequest receiveMessageRequest = new ReceiveMessageRequest(queueUrl);
		receiveMessageRequest.setMaxNumberOfMessages(1);
		receiveMessageRequest.setWaitTimeSeconds(waitTime);
		receiveMessageRequest.setVisibilityTimeout(visibilityTimeout);
		ReceiveMessageResult receiveMessageResult = awsConfiguration.amazonSQS().receiveMessage(receiveMessageRequest);
		List<Message> messageList = receiveMessageResult.getMessages();
		if (messageList.isEmpty()) {
			return null;
		}
		LOGGER.debug("Receiving the message from the queue." + messageList);
		System.out.println("Message received is:  " + messageList);
		return messageList.get(0);
	}

	@Override
	public void sendMessage(String messageBody, String queueName, Integer delaySeconds) {
		LOGGER.debug("Sending the message into the queue.");
		String queueUrl = null;
		try {
			queueUrl = awsConfiguration.amazonSQS().getQueueUrl(queueName).getQueueUrl();
		} catch (QueueDoesNotExistException queueDoesNotExistException) {
			CreateQueueResult createQueueResult = this.createQueue(queueName);
		}
		queueUrl = awsConfiguration.amazonSQS().getQueueUrl(queueName).getQueueUrl();
		SendMessageRequest sendMessageRequest = new SendMessageRequest().withQueueUrl(queueUrl)
				.withMessageBody(messageBody).withDelaySeconds(delaySeconds);
		awsConfiguration.amazonSQS().sendMessage(sendMessageRequest);
		
	}
	
}
