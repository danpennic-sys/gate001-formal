----------------------------- MODULE ContinuityV041 -----------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Nodes, GenesisCCR, MaxEvents, CCRUniverseSize
ASSUME IsFiniteSet(Nodes) /\ Nodes # {}
ASSUME GenesisCCR \in Nat
ASSUME MaxEvents \in Nat
ASSUME CCRUniverseSize \in Nat
ASSUME GenesisCCR \in 0..CCRUniverseSize

NULL == CCRUniverseSize + 1
CCR  == {GenesisCCR} \cup (0..CCRUniverseSize)

Range(seq) == {seq[i] : i \in 1..Len(seq)}

(* Deterministic ascending sequence for a finite set of naturals *)
CanonicalSeq(S) ==
    [i \in 1..Cardinality(S) |-> CHOOSE x \in S : Cardinality({y \in S : y < x}) = i-1]

VARIABLES ccrChain, lineage, pending, arbitrationOpen,
          federationView, ledgerAnchored, eventCount, history,
          arbitrationEpoch, arbitrationWinner, arbitrationLosers,
          arbitrationTerminations

vars == <<ccrChain, lineage, pending, arbitrationOpen,
          federationView, ledgerAnchored, eventCount, history,
          arbitrationEpoch, arbitrationWinner, arbitrationLosers,
          arbitrationTerminations>>

NoDup(seq) ==
    \A i,j \in 1..Len(seq): i # j => seq[i] # seq[j]

TypeOK ==
    /\ ccrChain \in Seq(CCR)
    /\ lineage \in Seq(CCR)
    /\ pending \in SUBSET CCR
    /\ arbitrationOpen \in BOOLEAN
    /\ federationView \in [Nodes -> CCR]
    /\ ledgerAnchored \in SUBSET CCR
    /\ eventCount \in 0..MaxEvents
    /\ history \in Seq([action: {"NormalAppend", "Stall", "PartialCommit", "OpenArbitration", "ResolveArbitration"}, ccr: CCR \cup {NULL}, winner: CCR \cup {NULL}, losers: SUBSET CCR, termCCRs: SUBSET CCR, epoch: Nat])
    /\ arbitrationEpoch \in Nat
    /\ arbitrationWinner \in CCR \cup {NULL}
    /\ arbitrationLosers \in SUBSET CCR
    /\ arbitrationTerminations \in SUBSET CCR

Init ==
    /\ ccrChain = <<GenesisCCR>>
    /\ lineage = <<GenesisCCR>>
    /\ pending = {}
    /\ arbitrationOpen = FALSE
    /\ federationView = [n \in Nodes |-> GenesisCCR]
    /\ ledgerAnchored = {}
    /\ eventCount = 0
    /\ history = <<>>
    /\ arbitrationEpoch = 0
    /\ arbitrationWinner = NULL
    /\ arbitrationLosers = {}
    /\ arbitrationTerminations = {}

Valid ==
    /\ ccrChain # <<>> => ccrChain[1] = GenesisCCR
    /\ NoDup(ccrChain)
    /\ NoDup(lineage)
    /\ \A c \in Range(ccrChain): c \in Range(lineage)
    /\ pending \subseteq Range(lineage)
    /\ ledgerAnchored \subseteq Range(lineage)
    /\ \A n \in Nodes: federationView[n] \in Range(lineage)
    /\ ledgerAnchored \cap pending = {}
    /\ (arbitrationOpen = FALSE => arbitrationWinner = NULL /\ arbitrationLosers = {} /\ arbitrationTerminations = {})
    /\ (arbitrationOpen = TRUE  => arbitrationWinner \in Range(lineage) /\ arbitrationLosers \subseteq Range(lineage) /\ arbitrationTerminations \subseteq Range(lineage) /\ arbitrationWinner \notin arbitrationLosers)

NormalAppend ==
    /\ eventCount < MaxEvents
    /\ \E newCCR \in CCR \ Range(lineage):
         /\ ccrChain' = Append(ccrChain, newCCR)
         /\ lineage' = Append(lineage, newCCR)
         /\ pending' = pending \cup {newCCR}
         /\ UNCHANGED <<arbitrationOpen, federationView, ledgerAnchored, arbitrationEpoch, arbitrationWinner, arbitrationLosers, arbitrationTerminations>>
         /\ eventCount' = eventCount + 1
         /\ history' = Append(history, [action |-> "NormalAppend", ccr |-> newCCR, winner |-> NULL, losers |-> {}, termCCRs |-> {}, epoch |-> arbitrationEpoch])

Stall ==
    /\ eventCount < MaxEvents
    /\ UNCHANGED <<ccrChain, lineage, pending, arbitrationOpen, federationView, ledgerAnchored, arbitrationEpoch, arbitrationWinner, arbitrationLosers, arbitrationTerminations>>
    /\ eventCount' = eventCount + 1
    /\ history' = Append(history, [action |-> "Stall", ccr |-> NULL, winner |-> NULL, losers |-> {}, termCCRs |-> {}, epoch |-> arbitrationEpoch])

PartialCommit ==
    /\ eventCount < MaxEvents
    /\ \E c \in pending:
         /\ ledgerAnchored' = ledgerAnchored \cup {c}
         /\ pending' = pending \ {c}
         /\ UNCHANGED <<ccrChain, lineage, arbitrationOpen, federationView, arbitrationEpoch, arbitrationWinner, arbitrationLosers, arbitrationTerminations>>
         /\ eventCount' = eventCount + 1
         /\ history' = Append(history, [action |-> "PartialCommit", ccr |-> c, winner |-> NULL, losers |-> {}, termCCRs |-> {}, epoch |-> arbitrationEpoch])

OpenArbitration ==
    /\ ~arbitrationOpen
    /\ eventCount < MaxEvents
    /\ \E winner \in Range(ccrChain),
         losers \in SUBSET (Range(ccrChain) \ ledgerAnchored),
         termCCRs \in SUBSET (CCR \ Range(lineage)):
         /\ losers # {}
         /\ termCCRs # {}
         /\ winner \notin losers
         /\ termCCRs \cap (pending \cup losers) = {}
         /\ arbitrationOpen' = TRUE
         /\ arbitrationEpoch' = arbitrationEpoch + 1
         /\ arbitrationWinner' = winner
         /\ arbitrationLosers' = losers
         /\ arbitrationTerminations' = termCCRs
         /\ pending' = pending \cup losers
         /\ lineage' = lineage \o CanonicalSeq(termCCRs)
         /\ federationView' = [n \in Nodes |-> winner]
         /\ ledgerAnchored' = ledgerAnchored \cup termCCRs
         /\ UNCHANGED <<ccrChain>>
         /\ eventCount' = eventCount + 1
         /\ history' = Append(history, [action |-> "OpenArbitration", ccr |-> winner, winner |-> winner, losers |-> losers, termCCRs |-> termCCRs, epoch |-> arbitrationEpoch + 1])

ResolveArbitration ==
    /\ arbitrationOpen = TRUE
    /\ eventCount < MaxEvents
    /\ arbitrationLosers \subseteq ledgerAnchored
    /\ \A loser \in arbitrationLosers: \A n \in Nodes: federationView[n] # loser
    /\ arbitrationOpen' = FALSE
    /\ arbitrationWinner' = NULL
    /\ arbitrationLosers' = {}
    /\ arbitrationTerminations' = {}
    /\ UNCHANGED <<ccrChain, lineage, pending, federationView, ledgerAnchored, arbitrationEpoch>>
    /\ eventCount' = eventCount + 1
    /\ history' = Append(history, [action |-> "ResolveArbitration", ccr |-> NULL, winner |-> arbitrationWinner, losers |-> arbitrationLosers, termCCRs |-> arbitrationTerminations, epoch |-> arbitrationEpoch])

Stutter ==
    UNCHANGED vars

Next ==
    \/ NormalAppend
    \/ Stall
    \/ PartialCommit
    \/ OpenArbitration
    \/ ResolveArbitration
    \/ Stutter

Spec == Init /\ [][Next]_vars

EpochBounded ==
    arbitrationEpoch <= eventCount

THEOREM Spec => []Valid
THEOREM Spec => []EpochBounded
=============================================================================
