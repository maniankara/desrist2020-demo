/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing a cv
type SmartContract struct {
	contractapi.Contract
}

// Cv describes a CV
type Cv struct {
	DocID   string `json:"DocID"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	Key    string `json:"Key"`
	Record *Cv
}

// InitLedger adds a base CV to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	cvs := []Cv{
		Cv{DocID: "abcID"},
	}

	for _, cv := range cvs {
		cvAsBytes, _ := json.Marshal(cv)
		err := ctx.GetStub().PutState("abc", cvAsBytes)

		if err != nil {
			return fmt.Errorf("Failed to put to world state. %s", err.Error())
		}
	}

	return nil
}

// CreateCv adds a new cv
func (s *SmartContract) CreateCv(ctx contractapi.TransactionContextInterface, id string, docID string) error {
	cv := Cv{
		DocID: docID,
	}

	fmt.Println("cv: ", cv)

	cvAsBytes, _ := json.Marshal(cv)

	fmt.Println("cv: ", cvAsBytes)

	return ctx.GetStub().PutState(id, cvAsBytes)
}

// QueryCv returns the cv
func (s *SmartContract) QueryCv(ctx contractapi.TransactionContextInterface, id string) (*Cv, error) {
	cvAsBytes, err := ctx.GetStub().GetState(id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if cvAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", id)
	}

	cv := new(Cv)
	_ = json.Unmarshal(cvAsBytes, cv)

	return cv, nil
}

// QueryAllCvs returns all cvs found in world state
func (s *SmartContract) QueryAllCvs(ctx contractapi.TransactionContextInterface) ([]QueryResult, error) {
	startKey := ""
	endKey := ""

	resultsIterator, err := ctx.GetStub().GetStateByRange(startKey, endKey)

	if err != nil {
			return nil, err
	}
	defer resultsIterator.Close()

	results := []QueryResult{}

	for resultsIterator.HasNext() {
			queryResponse, err := resultsIterator.Next()

			if err != nil {
					return nil, err
			}

			cv := new(Cv)
			_ = json.Unmarshal(queryResponse.Value, cv)

			queryResult := QueryResult{Key: queryResponse.Key, Record: cv}
			results = append(results, queryResult)
	}

	return results, nil
}

func main() {

	chaincode, err := contractapi.NewChaincode(new(SmartContract))

	if err != nil {
		fmt.Printf("Error create cv chaincode: %s", err.Error())
		return
	}

	if err := chaincode.Start(); err != nil {
		fmt.Printf("Error starting cv chaincode: %s", err.Error())
	}
}
