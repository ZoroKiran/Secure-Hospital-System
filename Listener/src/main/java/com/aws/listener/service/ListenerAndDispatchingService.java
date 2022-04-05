package com.aws.listener.service;

import java.io.IOException;
import org.json.simple.parser.ParseException;

public interface ListenerAndDispatchingService {
	
	public void generalFunction() throws IOException, ParseException;
	
	public byte[] convertToImg(String base64) throws IOException;
	


}
