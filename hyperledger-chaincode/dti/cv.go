/*
SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing a car
type SmartContract struct {
	contractapi.Contract
}

// Cv describes a CV
type Cv struct {
	DocID   string `json:"DocID"`
}

// QueryResult structure used for handling result of query
type QueryResult struct {
	ID    string `json:"Key"`
	Record *Cv
}

// InitLedger adds a base set of cars to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	cvs := []Cv{
		Cv{DocID: "abcID"},
	}

	for i, cv := range cvs {
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

	cvAsBytes, _ := json.Marshal(cv)

	return ctx.GetStub().PutState(id, cvAsBytes)
}

// QueryCv returns the cv
func (s *SmartContract) QueryCv(ctx contractapi.TransactionContextInterface, id string) (*Cv, error) {
	cvAsBytes, err := ctx.GetStub().GetState(id)

	if err != nil {
		return nil, fmt.Errorf("Failed to read from world state. %s", err.Error())
	}

	if cvAsBytes == nil {
		return nil, fmt.Errorf("%s does not exist", carNumber)
	}

	cv := new(Cv)
	_ = json.Unmarshal(cvAsBytes, cv)

	return cv, nil
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
