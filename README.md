# Decentralized Whistleblower Protection and Truth Verification System

A blockchain-based system for secure, anonymous whistleblowing with cryptographic evidence validation and legal protection coordination.

## System Overview

This system consists of five interconnected smart contracts that work together to protect whistleblowers while ensuring the integrity and verifiability of reported information:

### Core Contracts

1. **Anonymous Reporting Contract** (`anonymous-reporting.clar`)
    - Enables secure, untraceable submission of corruption and misconduct reports
    - Uses cryptographic hashing to maintain anonymity
    - Assigns unique report IDs for tracking without revealing identity

2. **Source Protection Contract** (`source-protection.clar`)
    - Maintains whistleblower anonymity while verifying report authenticity
    - Implements zero-knowledge proof concepts for identity verification
    - Manages access controls for sensitive information

3. **Evidence Validation Contract** (`evidence-validation.clar`)
    - Uses cryptographic proofs to verify document authenticity
    - Validates evidence without revealing sources or sensitive content
    - Maintains immutable audit trails for all evidence

4. **Journalist Collaboration Contract** (`journalist-collaboration.clar`)
    - Securely connects whistleblowers with verified investigative journalists
    - Manages encrypted communication channels
    - Tracks collaboration progress and outcomes

5. **Legal Protection Coordination Contract** (`legal-protection.clar`)
    - Provides legal defense funding and representation coordination
    - Manages protection fund distributions
    - Coordinates with legal aid organizations

## Key Features

- **Complete Anonymity**: Cryptographic protection of whistleblower identities
- **Evidence Integrity**: Immutable proof of document authenticity
- **Secure Collaboration**: Protected channels for journalist-source communication
- **Legal Support**: Automated legal protection fund management
- **Transparency**: Public verification of system integrity without compromising privacy

## Security Model

- All sensitive data is hashed before storage
- Access controls prevent unauthorized information disclosure
- Cryptographic proofs ensure evidence authenticity
- Multi-signature requirements for critical operations

## Getting Started

### Prerequisites

- Clarinet CLI installed
- Node.js 18+ for testing
- Basic understanding of Clarity smart contracts

### Installation

\`\`\`bash
git clone <repository-url>
cd whistleblower-protection-system
npm install
clarinet check
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Submitting an Anonymous Report

\`\`\`clarity
(contract-call? .anonymous-reporting submit-report
(hash160 "evidence-hash")
u1 ;; severity level
"Corruption in procurement process")
\`\`\`

### Validating Evidence

\`\`\`clarity
(contract-call? .evidence-validation validate-evidence
u1 ;; report-id
(hash160 "document-hash")
"SHA256-proof")
\`\`\`

### Requesting Legal Protection

\`\`\`clarity
(contract-call? .legal-protection request-protection
u1 ;; report-id
u1000000) ;; requested amount in microSTX
\`\`\`

## Architecture

The system uses a modular architecture where each contract handles specific responsibilities while maintaining secure interfaces for inter-contract communication.

## Contributing

Please read our contribution guidelines and ensure all tests pass before submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This system is designed for legitimate whistleblowing activities. Users are responsible for complying with applicable laws and regulations in their jurisdiction.
