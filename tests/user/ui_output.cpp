/*******************************************************************************
*   (c) 2019 ZondaX GmbH
*
*  Licensed under the Apache License, Version 2.0 (the "License");
*  you may not use this file except in compliance with the License.
*  You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
*  Unless required by applicable law or agreed to in writing, software
*  distributed under the License is distributed on an "AS IS" BASIS,
*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*  See the License for the specific language governing permissions and
*  limitations under the License.
********************************************************************************/

#include <gmock/gmock.h>

#include <iostream>
#include <fstream>
#include <nlohmann/json.hpp>
#include "lib/parser.h"
#include "util/common.h"

using ::testing::TestWithParam;
using ::testing::Values;
using json = nlohmann::json;

typedef struct {
    std::string name;
    std::string tx;
    std::string parsingErr;
    std::string validationErr;
    std::vector<std::string> expected;
} testcase_t;

class JsonTests : public ::testing::TestWithParam<testcase_t> {
public:
    struct PrintToStringParamName {
        template<class ParamType>
        std::string operator()(const testing::TestParamInfo<ParamType> &info) const {
            auto p = static_cast<testcase_t>(info.param);
            std::stringstream ss;
            ss << p.name;
            return ss.str();
        }
    };
};

std::vector<testcase_t> GetJsonTestCases() {
    auto answer = std::vector<testcase_t>();

    json j;
    std::ifstream inFile("testcases.json");
    EXPECT_TRUE(inFile.is_open()) << "Check that your working directory is pointing to the tests directory";
    inFile >> j;

    std::cout << "Number of testcases: " << j.size() << std::endl;

    for (auto &item : j) {
        std::string txStr = item["tx"].dump();

        answer.push_back(testcase_t{
            item["name"],
            txStr,
            item["parsingErr"],
            item["validationErr"],
            item["expected"],
        });
    }

    return answer;
}

void validate_testcase(const testcase_t &tc) {
    parser_context_t ctx;
    parser_error_t err;

    const auto *buffer = (const uint8_t *) tc.tx.c_str();
    uint16_t bufferLen = tc.tx.size();

    err = parser_parse(&ctx, buffer, bufferLen);
    ASSERT_EQ(parser_getErrorDescription(err), tc.parsingErr) << "Parsing error mismatch";

    if (err != parser_ok)
        return;

    err = parser_validate(&ctx);
    EXPECT_EQ( parser_getErrorDescription(err), tc.validationErr) << "Validation error mismatch";
}

void check_testcase(const testcase_t &tc) {
    parser_context_t ctx;
    parser_error_t err;

    const auto *buffer = (const uint8_t *) tc.tx.c_str();
    uint16_t bufferLen = tc.tx.size();

    err = parser_parse(&ctx, buffer, bufferLen);
    ASSERT_EQ(parser_getErrorDescription(err), tc.parsingErr)  << "Parsing error mismatch";

    if (err != parser_ok)
        return;

    auto output = dumpUI(&ctx, 40, 40);

    for (const auto &i : output) {
        std::cout << i << std::endl;
    }
    std::cout << std::endl << std::endl;

    EXPECT_EQ(output.size(), tc.expected.size());
    for (size_t i = 0; i < tc.expected.size(); i++) {
        if (i < output.size()) {
            EXPECT_THAT(output[i], testing::Eq(tc.expected[i]));
        }
    }
}

INSTANTIATE_TEST_CASE_P

(
    JsonTestCases,
    JsonTests,
    ::testing::ValuesIn(GetJsonTestCases()),
    JsonTests::PrintToStringParamName()
);

TEST_P(JsonTests, ValidateTestcase) { validate_testcase(GetParam()); }

TEST_P(JsonTests, CheckUIOutput) { check_testcase(GetParam()); }
