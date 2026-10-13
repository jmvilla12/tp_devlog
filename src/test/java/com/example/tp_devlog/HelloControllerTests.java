package com.example.tp_devlog;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class HelloControllerTests {

  private final HelloController controller = new HelloController();

  @Test
  void helloGreetsTheGivenName() {
    assertEquals("Hello, IMT!", controller.hello("IMT"));
  }

}
