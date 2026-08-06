package com.example.webapp;

import com.example.lib1.GreetingService;
import com.example.lib2.RequestProcessor;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet(urlPatterns = "/api")
public class MainServlet extends HttpServlet {
    private final GreetingService greetingService = new GreetingService();
    private final RequestProcessor requestProcessor = new RequestProcessor();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String name = req.getParameter("name");
        String greeting = greetingService.greet(name);
        resp.setContentType("text/plain");
        try (PrintWriter writer = resp.getWriter()) {
            writer.println(greeting);
            writer.println("Use POST to submit a payload at /api");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String payload = req.getParameter("payload");
        String result = requestProcessor.process(payload);
        resp.setContentType("text/plain");
        try (PrintWriter writer = resp.getWriter()) {
            writer.println("POST processed successfully.");
            writer.println(result);
        }
    }
}
