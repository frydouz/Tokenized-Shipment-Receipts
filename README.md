# 📦 Tokenized Shipment Receipts

> Transform supply chain tracking with NFT-powered digital shipment receipts

## 🌟 Overview

Tokenized Shipment Receipts creates a digital twin NFT for each shipment, enabling transparent and verifiable tracking as goods move across supply chains. Each shipment receipt is an NFT that can be transferred between parties, with milestone validation ensuring accountability at every step.

## ✨ Features

- 🎫 **NFT-Based Receipts**: Each shipment is minted as a unique non-fungible token
- 📍 **Milestone Tracking**: Add and verify checkpoints throughout the shipment journey
- 🔐 **Role-Based Access**: Carriers, verifiers, and shippers have specific permissions
- 🚚 **Status Management**: Track shipment status from creation to completion
- 📊 **Rich Metadata**: Store product details, weight, value, and special handling requirements
- ✅ **Customs Integration**: Mark shipments as customs-cleared
- 🔄 **Automatic Transfer**: NFT automatically transfers to receiver upon shipment completion

## 🏗️ Contract Architecture

### Core Components

**NFT Definition**
- `shipment-receipt`: Non-fungible token representing each shipment

**Data Structures**
- `shipments`: Main shipment data including origin, destination, parties, and status
- `shipment-milestones`: Checkpoint data with location, timestamp, and verification
- `shipment-metadata`: Product details and special handling flags
- `authorized-carriers`: Approved carriers who can create shipments
- `authorized-verifiers`: Approved verifiers who can validate milestones

## 🚀 Usage

### For Contract Owner

**Authorize Carriers**
```clarity
(contract-call? .Tokenized-Shipment-Receipts authorize-carrier 'SP2...)
```

**Authorize Verifiers**
```clarity
(contract-call? .Tokenized-Shipment-Receipts authorize-verifier 'SP3...)
```

### For Shippers

**Create a Shipment**
```clarity
(contract-call? .Tokenized-Shipment-Receipts create-shipment
  "New York, USA"           ;; origin
  "London, UK"              ;; destination
  'SP2CARRIER...            ;; carrier principal
  'SP3RECEIVER...           ;; receiver principal
  u100000                   ;; value in micro-STX
  u5000                     ;; weight in grams
  "Electronics"             ;; product type
  u50                       ;; quantity
  false                     ;; temperature-controlled
  true                      ;; fragile
)
```

### For Carriers

**Add Milestone**
```clarity
(contract-call? .Tokenized-Shipment-Receipts add-milestone
  u1                        ;; shipment-id
  "Port of Hamburg"         ;; location
  "Loaded onto vessel"      ;; description
)
```

**Update Status**
```clarity
(contract-call? .Tokenized-Shipment-Receipts update-shipment-status
  u1                        ;; shipment-id
  "in-transit"              ;; new status
)
```

**Complete Shipment**
```clarity
(contract-call? .Tokenized-Shipment-Receipts complete-shipment u1)
```

### For Verifiers

**Verify Milestone**
```clarity
(contract-call? .Tokenized-Shipment-Receipts verify-milestone
  u1                        ;; shipment-id
  u1                        ;; milestone-id
)
```

**Mark Customs Cleared**
```clarity
(contract-call? .Tokenized-Shipment-Receipts mark-customs-cleared u1)
```

### Query Functions

**Get Shipment Details**
```clarity
(contract-call? .Tokenized-Shipment-Receipts get-shipment u1)
```

**Get Milestone**
```clarity
(contract-call? .Tokenized-Shipment-Receipts get-milestone u1 u1)
```

**Get Milestone Count**
```clarity
(contract-call? .Tokenized-Shipment-Receipts get-milestone-count u1)
```

**Check NFT Owner**
```clarity
(contract-call? .Tokenized-Shipment-Receipts get-owner u1)
```

**Get Metadata**
```clarity
(contract-call? .Tokenized-Shipment-Receipts get-shipment-metadata u1)
```

## 🔒 Security & Permissions

| Role | Permissions |
|------|-------------|
| **Contract Owner** | Authorize/revoke carriers and verifiers, emergency transfers |
| **Shipper** | Create shipments (with authorized carrier), transfer NFT |
| **Carrier** | Add milestones, update status, complete shipments |
| **Verifier** | Verify milestones, mark customs cleared |
| **Receiver** | Automatically receives NFT upon shipment completion |

## 📋 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| `u100` | `err-owner-only` | Action restricted to contract owner |
| `u101` | `err-not-token-owner` | Caller is not the token owner |
| `u102` | `err-shipment-not-found` | Shipment ID does not exist |
| `u103` | `err-invalid-milestone` | Milestone not found |
| `u104` | `err-unauthorized` | Caller lacks required authorization |
| `u105` | `err-shipment-completed` | Cannot modify completed shipment |
| `u106` | `err-invalid-status` | Invalid status value |
| `u107` | `err-milestone-exists` | Milestone already exists |
| `u108` | `err-invalid-participant` | Invalid participant principal |
| `u109` | `err-already-verified` | Milestone already verified |

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🛠️ Development Setup

1. Install Clarinet:
```bash
brew install clarinet
```

2. Clone the repository:
```bash
git clone <repository-url>
cd Tokenized-Shipment-Receipts
```

3. Run checks:
```bash
clarinet check
```

## 📖 Example Workflow

1. **Contract Owner** authorizes a carrier and verifier
2. **Shipper** creates a shipment with an authorized carrier
3. **Carrier** adds milestones as shipment progresses
4. **Verifier** validates each milestone
5. **Carrier** marks customs-cleared status
6. **Carrier** completes the shipment
7. **NFT** automatically transfers to receiver

## 🌐 Use Cases

- 🚢 **International Shipping**: Track goods across borders with customs verification
- 📦 **E-commerce**: Provide buyers with transparent delivery tracking
- 🏭 **Manufacturing**: Monitor component movement in supply chain
- 🥶 **Cold Chain**: Track temperature-controlled shipments
- 💎 **High-Value Goods**: Secure tracking for valuable or fragile items

## 📄 License

MIT License

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

---

**Built with ❤️ on Stacks blockchain**
