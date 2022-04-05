package chaincode

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

type TransactionContract struct{
	contractapi.Contract
}
// Asset describes basic details of what makes up a simple asset
//Insert struct field in alphabetic order => to achieve determinism accross languages
// golang keeps the order when marshal to json but doesn't order automatically
type Asset struct {
	AppraisedValue int    `json:"AppraisedValue"`
	Color          string `json:"Color"`
	ID             string `json:"ID"`
	Owner          string `json:"Owner"`
	Size           int    `json:"Size"`
}

type Transaction struct {
	ID             string `json:"ID"`
	billID				string `json:"billID"`
	transactionID		string `json:"transactionID"`
	transactionAmount	string `json:"transactionAmount"`
	payer				string `json:"payer"`
	status				string `json:"status"`
	date				string `json:"date"`
	service				string `json:"service"`
	amount				string `json:"amount"`
}

// InitLedger adds a base set of assets to the ledger
func (s *SmartContract) InitLedger(ctx contractapi.TransactionContextInterface) error {
	assets := []Asset{
		{ID: "asset1", Color: "blue", Size: 5, Owner: "Tomoko", AppraisedValue: 300},
		{ID: "asset2", Color: "red", Size: 5, Owner: "Brad", AppraisedValue: 400},
		{ID: "asset3", Color: "green", Size: 10, Owner: "Jin Soo", AppraisedValue: 500},
		{ID: "asset4", Color: "yellow", Size: 10, Owner: "Max", AppraisedValue: 600},
		{ID: "asset5", Color: "black", Size: 15, Owner: "Adriana", AppraisedValue: 700},
		{ID: "asset6", Color: "white", Size: 15, Owner: "Michel", AppraisedValue: 800},
	}

	for _, asset := range assets {
		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(asset.ID, assetJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateAsset issues a new asset to the world state with given details.
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, id string, color string, size int, owner string, appraisedValue int) error {
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the asset %s already exists", id)
	}

	asset := Asset{
		ID:             id,
		Color:          color,
		Size:           size,
		Owner:          owner,
		AppraisedValue: appraisedValue,
	}
	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetJSON)
}

// ReadAsset returns the asset stored in the world state with given id.
func (s *SmartContract) ReadAsset(ctx contractapi.TransactionContextInterface, id string) (*Asset, error) {
	assetJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if assetJSON == nil {
		return nil, fmt.Errorf("the asset %s does not exist", id)
	}

	var asset Asset
	err = json.Unmarshal(assetJSON, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}

// UpdateAsset updates an existing asset in the world state with provided parameters.
func (s *SmartContract) UpdateAsset(ctx contractapi.TransactionContextInterface, id string, color string, size int, owner string, appraisedValue int) error {
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the asset %s does not exist", id)
	}

	// overwriting original asset with new asset
	asset := Asset{
		ID:             id,
		Color:          color,
		Size:           size,
		Owner:          owner,
		AppraisedValue: appraisedValue,
	}
	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetJSON)
}

// DeleteAsset deletes an given asset from the world state.
func (s *SmartContract) DeleteAsset(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the asset %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}

// AssetExists returns true when asset with given ID exists in world state
func (s *SmartContract) AssetExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	assetJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return assetJSON != nil, nil
}

// TransferAsset updates the owner field of asset with given id in world state, and returns the old owner.
func (s *SmartContract) TransferAsset(ctx contractapi.TransactionContextInterface, id string, newOwner string) (string, error) {
	asset, err := s.ReadAsset(ctx, id)
	if err != nil {
		return "", err
	}

	oldOwner := asset.Owner
	asset.Owner = newOwner

	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return "", err
	}

	err = ctx.GetStub().PutState(id, assetJSON)
	if err != nil {
		return "", err
	}

	return oldOwner, nil
}

// GetAllAssets returns all assets found in world state
func (s *SmartContract) GetAllAssets(ctx contractapi.TransactionContextInterface) ([]*Asset, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all assets in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var assets []*Asset
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Asset
		err = json.Unmarshal(queryResponse.Value, &asset)
		if err != nil {
			return nil, err
		}
		assets = append(assets, &asset)
	}

	return assets, nil
}

//For transaction contract
// InitLedger adds a base set of assets to the ledger
func (s *TransactionContract) TxnInitLedger(ctx contractapi.TransactionContextInterface) error {
	assets := []Transaction{
		{ID: "1", billID: "1", transactionID: "123456", transactionAmount: "35000", payer: "1", status: "approved", date: "3/22/22", service: "checkup", amount: "35000"},
		{ID: "2", billID: "2", transactionID: "234567", transactionAmount: "100000", payer: "1", status: "completed", date: "2/28/22", service: "checkup", amount: "100000"},
		{ID: "3", billID: "3", transactionID: "345678", transactionAmount: "250000", payer: "1", status: "completed", date: "3/21/22", service: "checkup", amount: "250000"},
		{ID: "4", billID: "4", transactionID: "456789", transactionAmount: "19000", payer: "1", status: "completed", date: "3/15/22", service: "checkup", amount: "19000" },
		{ID: "5", billID: "5", transactionID: "567890", transactionAmount: "21300", payer: "1", status: "completed", date: "3/15/22", service: "checkup", amount: "21300" },
		{ID: "6", billID: "6", transactionID: "678901", transactionAmount: "234200", payer: "1", status: "completed", date: "3/8/22", service: "checkup", amount: "234200" },
		{ID: "7", billID: "7", transactionID: "789012", transactionAmount: "96900", payer: "1", status: "completed", date: "3/3/22", service: "checkup", amount: "96900" },
		{ID: "8", billID: "8", transactionID: "890123", transactionAmount: "14800", payer: "1", status: "approved", date: "3/18/22", service: "checkup", amount: "14800"},
		{ID: "9", billID: "9", transactionID: "901234", transactionAmount: "167350", payer: "1", status: "completed", date: "3/17/22", service: "checkup", amount: "167350"},
		{ID: "10", billID: "10", transactionID: "243554", transactionAmount: "56900", payer: "1", status: "approved", date: "3/13/22", service: "checkup", amount: "56900"},
	}

	for _, asset := range assets {
		assetJSON, err := json.Marshal(asset)
		if err != nil {
			return err
		}

		err = ctx.GetStub().PutState(asset.ID, assetJSON)
		if err != nil {
			return fmt.Errorf("failed to put to world state. %v", err)
		}
	}

	return nil
}

// CreateAsset issues a new asset to the world state with given details.
func (s *TransactionContract) TxnCreateAsset(ctx contractapi.TransactionContextInterface, id string, bill string, txnID string, txnAmt string, pay string, sts string, dte string, svc string, amt string) error {
	exists, err := s.AssetExists(ctx, id)
	if err != nil {
		return err
	}
	if exists {
		return fmt.Errorf("the asset %s already exists", id)
	}

	asset := Transaction{
		ID:             id,		
		billID: bill,
        transactionID: txnID,
        transactionAmount: txnAmt,
    	payer: pay,
        status: sts,
        date: dte,
        service: svc,
        amount: amt,
	}
	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetJSON)
}

// ReadAsset returns the asset stored in the world state with given id.
func (s *TransactionContract) TxnReadAsset(ctx contractapi.TransactionContextInterface, id string) (*Transaction, error) {
	assetJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if assetJSON == nil {
		return nil, fmt.Errorf("the asset %s does not exist", id)
	}

	var asset Transaction
	err = json.Unmarshal(assetJSON, &asset)
	if err != nil {
		return nil, err
	}

	return &asset, nil
}

// UpdateAsset updates an existing asset in the world state with provided parameters.
func (s *TransactionContract) TxnUpdateAsset(ctx contractapi.TransactionContextInterface, id string, bill string, txnID string, txnAmt string, pay string, sts string, dte string, svc string, amt string) error {
	exists, err := s.TxnAssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the asset %s does not exist", id)
	}

	// overwriting original asset with new asset
	asset := Transaction{
		ID:             id,		
		billID: bill,
        transactionID: txnID,
        transactionAmount: txnAmt,
    	payer: pay,
        status: sts,
        date: dte,
        service: svc,
        amount: amt,
	}
	assetJSON, err := json.Marshal(asset)
	if err != nil {
		return err
	}

	return ctx.GetStub().PutState(id, assetJSON)
}

// DeleteAsset deletes an given asset from the world state.
func (s *TransactionContract) TxnDeleteAsset(ctx contractapi.TransactionContextInterface, id string) error {
	exists, err := s.TxnAssetExists(ctx, id)
	if err != nil {
		return err
	}
	if !exists {
		return fmt.Errorf("the asset %s does not exist", id)
	}

	return ctx.GetStub().DelState(id)
}

// AssetExists returns true when asset with given ID exists in world state
func (s *TransactionContract) TxnAssetExists(ctx contractapi.TransactionContextInterface, id string) (bool, error) {
	assetJSON, err := ctx.GetStub().GetState(id)
	if err != nil {
		return false, fmt.Errorf("failed to read from world state: %v", err)
	}

	return assetJSON != nil, nil
}

// TransferAsset updates the owner field of asset with given id in world state, and returns the old owner.
// func (s *TransactionContract) TransferAsset(ctx contractapi.TransactionContextInterface, id string, newOwner string) (string, error) {
// 	asset, err := s.ReadAsset(ctx, id)
// 	if err != nil {
// 		return "", err
// 	}

// 	oldOwner := asset.Owner
// 	asset.Owner = newOwner

// 	assetJSON, err := json.Marshal(asset)
// 	if err != nil {
// 		return "", err
// 	}

// 	err = ctx.GetStub().PutState(id, assetJSON)
// 	if err != nil {
// 		return "", err
// 	}

// 	return oldOwner, nil
// }

// GetAllAssets returns all assets found in world state
func (s *TransactionContract) TxnGetAllAssets(ctx contractapi.TransactionContextInterface) ([]*Transaction, error) {
	// range query with empty string for startKey and endKey does an
	// open-ended query of all assets in the chaincode namespace.
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var assets []*Transaction
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var asset Transaction
		err = json.Unmarshal(queryResponse.Value, &asset)
		if err != nil {
			return nil, err
		}
		assets = append(assets, &asset)
	}

	return assets, nil
}

