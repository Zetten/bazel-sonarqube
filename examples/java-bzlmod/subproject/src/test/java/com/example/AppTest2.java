package com.example;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class AppTest2 {
    @Test
    public void getMessage() {
        App app = new App();
        assertEquals("Default message is valid", app.getMessage(), "Hello World!");
    }
}
