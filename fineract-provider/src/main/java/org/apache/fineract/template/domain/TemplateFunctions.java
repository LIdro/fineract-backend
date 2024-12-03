/**
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements. See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership. The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.apache.fineract.template.domain;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import org.apache.fineract.infrastructure.core.service.DateUtils;

@SuppressWarnings({ "HideUtilityClassConstructor" })
public class TemplateFunctions {

    public static String now() {
        final DateTimeFormatter dateFormat = new DateTimeFormatterBuilder().appendPattern("yyyy/MM/dd HH:mm").toFormatter();
        final LocalDateTime date = DateUtils.getLocalDateTimeOfSystem();

        return dateFormat.format(date);
    }
}
