# Transient Approvals
This set of contract aims to extend current token standards with transient functionality.

## Contracts
```ml
tokens
├─ TransientERC20 — "Extends the ERC20 token standard with transient functionality"
├─ TransientERC721 — "Extends the ERC721 token standard with transient functionality"
├─ TransientERC1155 — "Extends the ERC1155 token standard with transient functionality"
├─ TransientWETH — "Extends the WETH token standard with transient functionality"
├─ utils
│  ├─ SafeTransientTransferLib — "Extends SafeTransferLib with transient functionality"
```

## Safety

This is **experimental software** and is provided on an "as is" and "as available" basis.

These contracts are **not designed with user safety** in mind but as a proof of concept:

- There are implicit invariants these contracts expect to hold.
- You should thoroughly read each contract you plan to use top to bottom.

I **do not give any warranties** and **will not be liable for any loss** incurred through any use of this codebase.

## Installation

To install with [**Foundry**](https://github.com/gakonst/foundry):

```sh
forge install IssyPro101/transient-approvals
```

## Acknowledgements
This repository is inspired by or directly modified from:
 - [Solmate](https://github.com/transmissions11/solmate)
 - [OpenZeppelin](https://github.com/OpenZeppelin/openzeppelin-contracts)