global class HTTPCalloutServiceMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
      
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"example":"test"}');
        response.setStatusCode(201);
        return response; 
    }
}