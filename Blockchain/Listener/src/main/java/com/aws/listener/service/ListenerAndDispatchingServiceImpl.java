package com.aws.listener.service;

import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.Base64;

import javax.imageio.ImageIO;

import org.apache.commons.io.FileUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.json.simple.JSONArray;
import org.json.simple.JSONObject;
import org.json.simple.parser.*;

import com.amazonaws.services.sqs.model.Message;
import com.aws.listener.config.AwsConfiguration;
import com.aws.listener.constants.Constants;
import com.amazonaws.services.sqs.AmazonSQS;
import com.amazonaws.services.sqs.AmazonSQSClientBuilder;
import com.amazonaws.services.sqs.model.AmazonSQSException;
import com.amazonaws.services.sqs.model.CreateQueueResult;
import com.amazonaws.services.sqs.model.Message;
import com.amazonaws.services.sqs.model.SendMessageBatchRequest;
import com.amazonaws.services.sqs.model.SendMessageBatchRequestEntry;
import com.amazonaws.services.sqs.model.SendMessageRequest;

@Service
public class ListenerAndDispatchingServiceImpl implements ListenerAndDispatchingService {

	@Autowired
	private AwsConfiguration awsConfiguration;
	
	@Autowired
	private SqsService sqsService;
	

	@Override
	public void generalFunction() throws IOException, ParseException {
		System.out.println("Listener and dispatch main routine.");
		while (true) {
			Message message = sqsService.receiveMessage(Constants.INPUTQUEUENAME, 20, 15);
			if (message == null) {
				continue;
			}
			//String messageBody = sqsService.parseImageName(message.getBody());
			//System.out.println(message.toString());
			String messageBody = message.getBody();

			Object obj = new JSONParser().parse(messageBody);
	          
	        // typecasting obj to JSONObject
	        JSONObject jo = (JSONObject) obj;
	         
	        // getting name and image string	
	        
            String Owner = (String) jo.get("owner");
            //String nameImageIn = fullnameImageIn.split("\\.")[0];
			String AppraisedValue = (String) jo.get("amount");
			String ID = (String) jo.get("ID");
			String Color = (String) jo.get("status");
			String query = (String) jo.get("query");
			//String trimstrImageIn = strImageIn.substring(2, strImageIn.length() - 1);
	        //System.out.println(fullnameImageIn);
			
			String fullArgument = "";
			switch (query) {
			case "GetAllAssets": fullArgument = "'{\"Args\":[\"GetAllAssets\"]}'";
			break;
			case "UpdateAsset": fullArgument = "'{\"function\":\"UpdateAsset\",\"Args\":[";
			break;
			case "ReadAsset": fullArgument = "'{\"function\":\"ReadAsset\",\"Args\":[";
			break;
			case "CreateAsset": fullArgument = "'{\"function\":\"CreateAsset\",\"Args\":[";
			break;
			}
			
			if(query.equals("GetAllAssets")) {
				fullArgument = "'{\"Args\":[\"GetAllAssets\"]}'";
			}else {
				
			}
	
		
			System.out.println("Posting transaction to blockchain.");
			System.out.println("Argument 1: " + fullArgument);
			String predictValue = null;
			
			try {
				System.out.println("Calling process builder...");
				ProcessBuilder pb = new ProcessBuilder("blockchain.sh", fullArgument);
				Process p = pb.start();
				p.waitFor();
				BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
				BufferedReader ebr = new BufferedReader(new InputStreamReader(p.getErrorStream()));
				predictValue = br.readLine();
				System.out.println("Reading input stream...");
				if(ebr.readLine() != null) {
					predictValue = predictValue + ebr.readLine();
				}
				br.close();
				p.destroy();
				
			} catch (Exception e) {
				System.out.println(e.getMessage());
				System.out.println(e.getStackTrace());
			}
			System.out.println("Posted transaction: \n"+ predictValue);
				       
			//sqsService.sendMessage("{\"uuid\": \"" + uuidImageIn + "\", \"result\": \"" + predictValue + "\"}", Constants.OUTPUTQUEUE, 0);
			sqsService.deleteMessage(message, Constants.INPUTQUEUENAME);
			
		}		
	}
	
    public byte[] convertToImg(String base64) throws IOException  
    {  
         return Base64.getDecoder().decode(base64);  
    }  
    


}
