module lang::java::transformations::junit::TestFinal

import ParseTree;
import lang::java::\syntax::Java18;
import lang::java::transformations::junit::MainProgram;
import lang::java::transformations::junit::AssertAll;
import lang::java::transformations::junit::ConditionalAssertion;
import lang::java::transformations::junit::ExpectedException;
import lang::java::transformations::junit::ExpectedTimeout;
import lang::java::transformations::junit::ParameterizedTest;
import lang::java::transformations::junit::RepeatedTest;
import lang::java::transformations::junit::SimpleAnnotations;
import lang::java::transformations::junit::TempDir;
import util::Testing;

import IO;

private CompilationUnit expectedExceptionTransform(CompilationUnit c) {
  if(verifyExpectedException(c)) c = executeExpectedExceptionTransformation(c); 
  return c;
}

private CompilationUnit expectedTimeoutTransform(CompilationUnit c) {
  if(verifyTimeOut(c)) c = executeExpectedTimeoutTransformation(c); 
  return c;
}

private CompilationUnit simpleAnnotationTransform(CompilationUnit c) {
  if(verifySimpleAnnotations(c)) c = executeSimpleAnnotationsTransformation(c); 
  return c;
}

test bool main() {
  list[bool ()] tests = [
    maintest
  ];

  return runAndReportMultipleTests(tests);
}

list[Transformation] transformations() = [
    transformation("ExpectedException", expectedExceptionTransform),
    transformation("ExpectedTimeout", expectedTimeoutTransform),
    transformation("SimpleAnnotations", simpleAnnotationTransform),
    transformation("AssertAll", executeAssertAllTransformation),
    transformation("ConditionalAssertion", executeConditionalAssertionTransformation),
    transformation("ParameterizedTest", executeParameterizedTestTransformation),
    transformation("RepeatedTest", executeRepeatedTestTransformation),
    transformation("TempDir", executeTempDirTransformation)
];

str code1() =
"/*
' * Copyright 2014-2021 Real Logic Limited.
' *
' * Licensed under the Apache License, Version 2.0 (the \"License\");
' * you may not use this file except in compliance with the License.
' * You may obtain a copy of the License at
' *
' * https://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software
' * distributed under the License is distributed on an \"AS IS\" BASIS,
' * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' * See the License for the specific language governing permissions and
' * limitations under the License.
' */
'package io.aeron.driver;
'
'import static org.hamcrest.MatcherAssert.assertThat;
'import static org.hamcrest.Matchers.lessThanOrEqualTo;
'
'import java.util.concurrent.TimeUnit;
'import org.junit.jupiter.api.Test;
'
'public class OptimalMulticastDelayGeneratorTest
'{
'    private static final long MAX_BACKOFF = TimeUnit.MILLISECONDS.toNanos(60);
'    private static final long GROUP_SIZE = 10;
'
'  private final OptimalMulticastDelayGenerator generator =
'      new OptimalMulticastDelayGenerator(MAX_BACKOFF, GROUP_SIZE);
'
'    @Test
'    public void shouldNotExceedTmaxBackoff()
'    {
'        for (int i = 0; i \< 100_000; i++)
'        {
'            final double delay = generator.generateNewOptimalDelay();
'            assertThat(delay, lessThanOrEqualTo((double)MAX_BACKOFF));
'        }
'    }
'}";

str expectedCode1() =
"/*
' * Copyright 2014-2021 Real Logic Limited.
' *
' * Licensed under the Apache License, Version 2.0 (the \"License\");
' * you may not use this file except in compliance with the License.
' * You may obtain a copy of the License at
' *
' * https://www.apache.org/licenses/LICENSE-2.0
' *
' * Unless required by applicable law or agreed to in writing, software
' * distributed under the License is distributed on an \"AS IS\" BASIS,
' * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
' * See the License for the specific language governing permissions and
' * limitations under the License.
' */
'package io.aeron.driver;
'
'import static org.hamcrest.MatcherAssert.assertThat;
'import static org.hamcrest.Matchers.lessThanOrEqualTo;
'
'import java.util.concurrent.TimeUnit;
'import org.junit.jupiter.api.Test;
'
'public class OptimalMulticastDelayGeneratorTest
'{
'    private static final long MAX_BACKOFF = TimeUnit.MILLISECONDS.toNanos(60);
'    private static final long GROUP_SIZE = 10;
'
'  private final OptimalMulticastDelayGenerator generator =
'      new OptimalMulticastDelayGenerator(MAX_BACKOFF, GROUP_SIZE);
'
'    @RepeatedTest(100000)
'    public void shouldNotExceedTmaxBackoff()
'    {
'       final double delay = generator.generateNewOptimalDelay();
'       assertThat(delay, lessThanOrEqualTo((double)MAX_BACKOFF));
'    }
'}";

test bool aeron() {
  expected = parse(#CompilationUnit, expectedCode1());
  <res, _, _> = applyTransformations(code1(), 0, initTransformationsCount(transformations()), transformations());
  println(res);

  return expected == res;
}


str code2() =
"package io.quarkus.deployment;
'
'import static org.junit.jupiter.api.Assertions.assertEquals;
'
'import org.junit.jupiter.api.Test;
'
'public class CapabilityNameTest {
'
'    @Test
'    public void testName() {
'        assertEquals(\"io.quarkus.agroal\", Capability.AGROAL.getName());
'        assertEquals(\"io.quarkus.security.jpa\", Capability.SECURITY_JPA.getName());
'        assertEquals(\"io.quarkus.container.image.docker\", Capability.CONTAINER_IMAGE_DOCKER.getName());
'    }
'
'}";

str expectedCode2() =
"package io.quarkus.deployment;
'
'import static org.junit.jupiter.api.Assertions.assertEquals;
'
'import org.junit.jupiter.api.Test;
'
'public class CapabilityNameTest {
'
'    @Test
'    public void testName() {
'      Assertions.assertAll(
'        () -\> assertEquals(\"io.quarkus.agroal\", Capability.AGROAL.getName()),
'        () -\> assertEquals(\"io.quarkus.security.jpa\", Capability.SECURITY_JPA.getName()),
'        () -\> assertEquals(\"io.quarkus.container.image.docker\", Capability.CONTAINER_IMAGE_DOCKER.getName())
'      );
'    }
'}";

test bool quarkus() {
  expected = parse(#CompilationUnit, expectedCode2());
  <res, _, _> = applyTransformations(code2(), 0, initTransformationsCount(transformations()), transformations());
  println(res);

  return expected == res;
}

str code3() =
"public abstract class WritableConfigurationTest {
'    private WriteConfiguration config;
'    public abstract WriteConfiguration getConfig();
'    @BeforeEach
'    public void setup() {
'        config = getConfig();
'    }
'    @AfterEach
'    public void cleanup() {
'        config.close();
'    }
'    @Test
'    public void configTest() {
'        config.set(\"test.key\",\"world\");
'        config.set(\"test.bar\", 100);
'        config.set(\"storage.xyz\", true);
'        config.set(\"storage.abc\", Boolean.FALSE);
'        config.set(\"storage.duba\", new String[]{\"x\", \"y\"});
'        config.set(\"times.60m\", Duration.ofMinutes(60));
'        config.set(\"obj\", new Object()); // necessary for AbstractConfiguration.getSubset
'    assertEquals(\"world\", config.get(\"test.key\", String.class));
'    assertEquals(ImmutableSet.of(\"test.key\", \"test.bar\"), Sets.newHashSet(config.getKeys(\"test\")));
'    // assertEquals(ImmutableSet.of(\"test.key\", \"test.bar\", \"test.baz\"),
'    // Sets.newHashSet(config.getKeys(\"test\")));
'    assertEquals(
'        ImmutableSet.of(\"storage.xyz\", \"storage.duba\", \"storage.abc\"),
'        Sets.newHashSet(config.getKeys(\"storage\")));
'    assertEquals(100, config.get(\"test.bar\", Integer.class).intValue());
'    // assertEquals(1,config.get(\"test.baz\",Integer.class).intValue());
'    assertEquals(true, config.get(\"storage.xyz\", Boolean.class));
'    assertEquals(false, config.get(\"storage.abc\", Boolean.class));
'    assertArrayEquals(new String[] {\"x\", \"y\"}, config.get(\"storage.duba\", String[].class));
'    assertEquals(Duration.ofMinutes(60), config.get(\"times.60m\", Duration.class));
'    assertTrue(Object.class.isAssignableFrom(config.get(\"obj\", Object.class).getClass()));
'    }
'}";

str expectedCode3() =
"public abstract class WritableConfigurationTest {
'    private WriteConfiguration config;
'    public abstract WriteConfiguration getConfig();
'    @BeforeEach
'    public void setup() {
'        config = getConfig();
'    }
'    @AfterEach
'    public void cleanup() {
'        config.close();
'    }
'    @Test
'    public void configTest() {
'     config.set(\"test.key\",\"world\");
'     config.set(\"test.bar\", 100);
'     config.set(\"storage.xyz\", true);
'     config.set(\"storage.abc\", Boolean.FALSE);
'     config.set(\"storage.duba\", new String[]{\"x\", \"y\"});
'     config.set(\"times.60m\", Duration.ofMinutes(60));
'     config.set(\"obj\", new Object());
'     Assertions.assertAll(
'       () -\> assertEquals(\"world\", config.get(\"test.key\", String.class)),
'       () -\> assertEquals(ImmutableSet.of(\"test.key\", \"test.bar\"), Sets.newHashSet(config.getKeys(\"test\"))),
'       () -\> assertEquals(
'                  ImmutableSet.of(\"storage.xyz\", \"storage.duba\", \"storage.abc\"),
'                  Sets.newHashSet(config.getKeys(\"storage\"))),
'       () -\> assertEquals(100, config.get(\"test.bar\", Integer.class).intValue()),
'       () -\> assertEquals(true, config.get(\"storage.xyz\", Boolean.class)),
'       () -\> assertEquals(false, config.get(\"storage.abc\", Boolean.class)),
'       () -\> assertArrayEquals(new String[] {\"x\", \"y\"}, config.get(\"storage.duba\", String[].class)),
'       () -\> assertEquals(Duration.ofMinutes(60), config.get(\"times.60m\", Duration.class)),
'       () -\> assertTrue(Object.class.isAssignableFrom(config.get(\"obj\", Object.class).getClass()))
'     );
'    }
'}";

test bool janusGraph() {
  expected = parse(#CompilationUnit, expectedCode3());
  <res, _, _> = applyTransformations(code3(), 0, initTransformationsCount(transformations()), transformations());

  return expected == res;
}

str code4() =
"public class VaultSettingsJsonAdapterTest {
'
'  private final VaultSettingsJsonAdapter adapter = new VaultSettingsJsonAdapter();
'
'  @Test
'  public void testDeserialize() throws IOException {
'    String json =
'        \"{\\\"id\\\": \\\"foo\\\", \\\"path\\\": \\\"/foo/bar\\\", \\\"displayName\\\": \\\"test\\\", \\\"winDriveLetter\\\":\"
'            + \" \\\"X\\\", \\\"shouldBeIgnored\\\": true, \\\"individualMountPath\\\": \\\"/home/test/crypto\\\",\"
'            + \" \\\"mountFlags\\\":\\\"--foo --bar\\\"}\";
'    JsonReader jsonReader = new JsonReader(new StringReader(json));
'
'    VaultSettings vaultSettings = adapter.read(jsonReader);
'    Assertions.assertEquals(\"foo\", vaultSettings.getId());
'    Assertions.assertEquals(Paths.get(\"/foo/bar\"), vaultSettings.path().get());
'    Assertions.assertEquals(\"test\", vaultSettings.displayName().get());
'    Assertions.assertEquals(\"X\", vaultSettings.winDriveLetter().get());
'    Assertions.assertEquals(\"/home/test/crypto\", vaultSettings.customMountPath().get());
'    Assertions.assertEquals(\"--foo --bar\", vaultSettings.mountFlags().get());
'  }
'}";

str expectedCode4() =
"public class VaultSettingsJsonAdapterTest {
'
'  private final VaultSettingsJsonAdapter adapter = new VaultSettingsJsonAdapter();
'
'  @Test
'  public void testDeserialize() throws IOException {
'    String json =
'        \"{\\\"id\\\": \\\"foo\\\", \\\"path\\\": \\\"/foo/bar\\\", \\\"displayName\\\": \\\"test\\\", \\\"winDriveLetter\\\":\"
'            + \" \\\"X\\\", \\\"shouldBeIgnored\\\": true, \\\"individualMountPath\\\": \\\"/home/test/crypto\\\",\"
'            + \" \\\"mountFlags\\\":\\\"--foo --bar\\\"}\";
'    JsonReader jsonReader = new JsonReader(new StringReader(json));
'
'    VaultSettings vaultSettings = adapter.read(jsonReader);
'    Assertions.assertAll(
'     () -\> Assertions.assertEquals(\"foo\", vaultSettings.getId()),
'     () -\> Assertions.assertEquals(Paths.get(\"/foo/bar\"), vaultSettings.path().get()),
'     () -\> Assertions.assertEquals(\"test\", vaultSettings.displayName().get()),
'     () -\> Assertions.assertEquals(\"X\", vaultSettings.winDriveLetter().get()),
'     () -\> Assertions.assertEquals(\"/home/test/crypto\", vaultSettings.customMountPath().get()),
'     () -\> Assertions.assertEquals(\"--foo --bar\", vaultSettings.mountFlags().get())
'    );
'  }
'}";

test bool cryptomator() {
  expected = parse(#CompilationUnit, expectedCode4());
  <res, _, _> = applyTransformations(code4(), 0, initTransformationsCount(transformations()), transformations());

  return expected == res;
}

test bool maintest() {
  testMain();
}
