package com.separate.subsubproject;

import static org.junit.Assert.assertEquals; 
import org.junit.Test;

public class SeparateSubSubAppTest {
    SeparateSubSubApp app = new SeparateSubSubApp();

    @Test
    public void testSecretMessage() {
        assertEquals("Test knows the secret message", "Don't tell.", app.getSecretMessage());
    }
}
