global class PremCalloutServiceMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        //System.assertEquals('callout:OracleCredentials', request.getEndpoint());
        //System.assertEquals('POST', request.getMethod());
        
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"example":"test"}');
        response.setStatusCode(201);
        return response; 
    }
}