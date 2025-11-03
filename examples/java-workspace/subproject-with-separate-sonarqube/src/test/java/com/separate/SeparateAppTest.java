package com.separate;

import static org.junit.Assert.assertEquals;

import org.junit.Test;

public class SeparateAppTest {
    @Test
    public void getMessage() {
        SeparateApp app = new SeparateApp();
        assertEquals("Default message is valid", app.getMessage(), "Hello from another (separate) world.");
    }
}
