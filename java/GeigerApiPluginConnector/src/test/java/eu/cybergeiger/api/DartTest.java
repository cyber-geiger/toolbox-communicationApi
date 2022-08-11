package eu.cybergeiger.api;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestInfo;

import java.io.File;
import java.io.IOException;
import java.lang.reflect.Method;
import java.util.*;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class DartTest {
  private static final int testMsTimeout = 30000;
  private final Map<Method, Process> runners = new HashMap<>();

  private static Method getTestMethod(TestInfo info) {
    return info.getTestMethod().orElseThrow(
      () -> new RuntimeException("Could not retrieve test method.")
    );
  }

  @BeforeEach
  public void MaybeExecuteDartPart(TestInfo info) {
    Method method = getTestMethod(info);
    String[] classNames = method.getDeclaringClass().getName().split("\\$");
    String[] baseClassSegments = classNames[0].split("\\.");
    String filePath = "./" + String.join("/", baseClassSegments) + ".dart";
    boolean isWindows = System.getProperty("os.name").toLowerCase().startsWith("windows");
    ArrayList<String> command = new ArrayList<>(Arrays.asList(
      isWindows ? "cmd.exe" : "sh",
      isWindows ? "/c" : "-c",
      "flutter",
      "test",
      filePath,
      "--name",
      method.getName()
    ));
    for (int i = 1; i < classNames.length; i++) {
      command.add("--name");
      command.add(classNames[i]);
    }

    Process runner;
    try {
      runner = new ProcessBuilder(command)
        .redirectOutput(ProcessBuilder.Redirect.INHERIT)
        .redirectError(ProcessBuilder.Redirect.INHERIT)
        .directory(new File("./src/test/dart/"))
        .start();
    } catch (IOException e) {
      throw new RuntimeException("Failed to execute dart counterpart.", e);
    }
    runners.put(method, runner);
  }

  @AfterEach
  public void MaybeCheckDartResult(TestInfo info) throws TimeoutException {
    Method method = getTestMethod(info);
    Process runner = runners.get(method);
    if (runner == null) return;
    try {
      if (!runner.waitFor(testMsTimeout, TimeUnit.MILLISECONDS)) {
        runner.destroy();
        throw new TimeoutException("Dart side did not exit in time.");
      }
      if (runner.exitValue() != 0)
        throw new AssertionError("Dart side did not exit successfully.");
    } catch (InterruptedException e) {
      throw new RuntimeException("Dart side result check was interrupted.", e);
    } finally {
      runner.destroy();
      runners.remove(method);
    }
  }
}
