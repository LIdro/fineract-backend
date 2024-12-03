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
package org.apache.fineract.portfolio.savings.jobs.payduesavingscharges;

import org.apache.fineract.infrastructure.jobs.service.JobName;
import org.apache.fineract.portfolio.savings.service.SavingsAccountChargeReadPlatformService;
import org.apache.fineract.portfolio.savings.service.SavingsAccountWritePlatformService;
import org.springframework.batch.core.Job;
import org.springframework.batch.core.Step;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.launch.support.RunIdIncrementer;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.PlatformTransactionManager;

@Configuration
public class PayDueSavingsChargesConfig {

    @Autowired
    private JobRepository jobRepository;
    @Autowired
    private PlatformTransactionManager transactionManager;
    @Autowired
    private SavingsAccountChargeReadPlatformService savingsAccountChargeReadPlatformService;
    @Autowired
    private SavingsAccountWritePlatformService savingsAccountWritePlatformService;

    @Bean
    protected Step payDueSavingsChargesStep() {
        return new StepBuilder(JobName.PAY_DUE_SAVINGS_CHARGES.name(), jobRepository)
                .tasklet(payDueSavingsChargesTasklet(), transactionManager).build();
    }

    @Bean
    public Job payDueSavingsChargesJob() {
        return new JobBuilder(JobName.PAY_DUE_SAVINGS_CHARGES.name(), jobRepository).start(payDueSavingsChargesStep())
                .incrementer(new RunIdIncrementer()).build();
    }

    @Bean
    public PayDueSavingsChargesTasklet payDueSavingsChargesTasklet() {
        return new PayDueSavingsChargesTasklet(savingsAccountChargeReadPlatformService, savingsAccountWritePlatformService);
    }
}
