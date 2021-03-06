// Copyright 2014 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package com.google.devtools.build.lib.events;

import static org.junit.Assert.assertEquals;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.JUnit4;

import java.util.Set;

/**
 * Tests {@link AbstractEventHandler}.
 */
@RunWith(JUnit4.class)
public class AbstractEventHandlerTest {

  private static AbstractEventHandler create(Set<EventKind> mask) {
    return new AbstractEventHandler(mask) {
        @Override
        public void handle(Event event) {}
      };
  }

  @Test
  public void retainsEventMask() {
    assertEquals(EventKind.ALL_EVENTS,
                 create(EventKind.ALL_EVENTS).getEventMask());
    assertEquals(EventKind.ERRORS_AND_WARNINGS,
                 create(EventKind.ERRORS_AND_WARNINGS).getEventMask());
    assertEquals(EventKind.ERRORS,
                 create(EventKind.ERRORS).getEventMask());
  }

}
