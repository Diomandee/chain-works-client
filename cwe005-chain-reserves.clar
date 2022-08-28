;; (impl-trait .vault-trait.vault-trait)
;; (use-trait ft-trait .sip010-ft-trait.sip010-ft-trait)
;; (use-trait vault-trait .vault-trait.vault-trait)
;; (use-trait oracle-trait .oracle-trait.oracle-trait)
(use-trait chain-usda-trait .chain-usda-trait.chain-usda-trait)

;; errors
(define-constant ERR-NOT-AUTHORIZED u11401)
(define-constant ERR-TRANSFER-FAILED u112)
(define-constant ERR-MINTER-FAILED u113)
(define-constant ERR-BURN-FAILED u114)
(define-constant ERR-DEPOSIT-FAILED u115)
(define-constant ERR-WITHDRAW-FAILED u116)
(define-constant ERR-MINT-FAILED u117)
(define-constant ERR-WRONG-TOKEN u118)
(define-constant ERR-TOO-MUCH-DEBT u119)

(define-constant CONTRACT_OWNER tx-sender)


(define-data-var governance-token-principal principal .cwe000-chain-usda)

(define-public (is-dao-or-extension)
	(ok (asserts! (or (is-eq tx-sender .chain-dao) (contract-call? .chain-dao is-extension contract-caller)) (err ERR-NOT-AUTHORIZED)))
)

;; --- Internal DAO functions

;; Governance token

(define-public (set-governance-token (governance-token <chain-usda-trait>))
	(begin
		(try! (is-dao-or-extension))
		(ok (var-set governance-token-principal (contract-of governance-token)))
	)
)


;; calculate the amount of stablecoins to mint, based on posted STX amount
;; ustx-amount * stx-price == dollar-collateral-posted
;; (dollar-collateral-posted / collateral-to-debt-ratio) == stablecoins to mint
(define-public (calculate-usda-count
  (token (string-ascii 12))
  (ustx-amount uint)
  (collateralization-ratio uint)
)
  (let (
    (stx-price u1))
    (let ((amount
      (+
        (* ustx-amount u100)
        collateralization-ratio
      ))
    )
      (ok amount)
    )
  )
)

(define-public (calculate-current-collateral-to-debt-ratio
  (token (string-ascii 12))
  (debt uint)
  (ustx uint)
)
  (let (
    (stx-price u1))
    (if (> debt u0)
      (ok u1)
      (err u0)
    )
  )
)

;; accept collateral in STX tokens
;; save STX in stx-reserve-address
;; calculate price and collateralisation ratio
(define-public (collateralize-and-mint
  (sip010-asset <chain-usda-trait>)
  (token-string (string-ascii 12))
  (ustx-amount uint)
  (debt uint)
  (sender principal)

)
  (begin
    ;; (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq token-string "USDA") (err ERR-WRONG-TOKEN))
    ;; (unwrap! (contract-call? .usda transfer ustx-amount sender (as-contract tx-sender) none) (err ERR-MINTER-FAILED)) 
    (ok true)
  )
)

;; deposit extra collateral in vault
(define-public (deposit (sip010-asset <chain-usda-trait>) (additional-usda-amount uint))
  (begin
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))

    ;; (unwrap! (contract-call? .usda transfer additional-usda-amount tx-sender (as-contract tx-sender) none) (err ERR-DEPOSIT-FAILED))
   (ok true)
  )
)

;; withdraw collateral (e.g. if collateral goes up in value)
(define-public (withdraw (sip010-asset <chain-usda-trait>) (token-string (string-ascii 12)) (vault-owner principal) (ustx-amount uint))
  (begin
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq token-string "STX") (err ERR-WRONG-TOKEN))

    (match (print (as-contract (stx-transfer? ustx-amount tx-sender vault-owner)))
      success (ok true)
      error (err ERR-WITHDRAW-FAILED)
    )
  )
)

;; mint new tokens when collateral to debt allows it (i.e. > collateral-to-debt-ratio)
;; (define-public (mint
;;   (token-string (string-ascii 12))
;;   (vault-owner principal)
;;   (ustx-amount uint)
;;   (current-debt uint)
;;   (extra-debt uint)
;;   (collateralization-ratio uint)
;; )
;;   (begin

;;     (let (
;;       (max-new-debt (- (unwrap-panic (calculate-usda-count token-string ustx-amount collateralization-ratio)) current-debt)))
;;       (if (>= max-new-debt extra-debt)
;;         (match (print  (contract-call? .cwe000-chain-usda mint-ft vault-owner extra-debt .cwe000-chain-usda))
;;           success (ok true)
;;           error (err ERR-MINT-FAILED)
;;         )
;;         (err ERR-TOO-MUCH-DEBT)
;;       )
;;     )
;;   )
;; )

;; burn stablecoin to free up STX tokens
;; method assumes position has not been liquidated
;; and thus collateral to debt ratio > liquidation ratio
;; (define-public (burn (token <chain-usda-trait>) (vault-owner principal) (collateral-to-return uint))
;;   (begin
 
;;     (unwrap! (contract-call? .cwe000-chain-usda burn-ft collateral-to-return  vault-owner .cwe000-chain-usda) (err ERR-TRANSFER-FAILED))
;;     (ok true)
;;   )
;; )

(define-public (redeem-collateral (chain-id uint) (stx-collateral uint) (owner principal))
  (begin
          ;; (try! (contract-call? .usda transfer stx-collateral .chain-pool tx-sender none))
          (ok true)
  )
)

;; ---------------------------------------------------------
;; Admin Functions
;; ---------------------------------------------------------

(define-read-only (get-stx-balance)
  (stx-get-balance (as-contract tx-sender))
)

;; this should be called when upgrading contracts
;; STX reserve should only contain STX
(define-public (migrate-funds (new-vault principal))
  (begin
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))

    (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender CONTRACT_OWNER))
  )
)


(define-public (migrate-state (new-vault principal))
  (begin
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (ok true)
  )
)