------------------------------ MODULE whatapp ------------------------------

EXTENDS Naturals, FiniteSets, Sequences, TLC

(*
  会話単位の全順序（総順序）の最小モデル。
  - Ingress は会話ごとに nextSeq[c] により通番（seq）を割当てる。
  - メッセージは Log（唯一の正本／真実の源泉）に追加される。
  - Delivery は Log に記録済みの任意のメッセージを、任意の受信者へ（遅延し得る形で）配送し得る。
  - Client は会話ごとに seq の昇順に従ってメッセージを表示する。
*)

CONSTANTS
  Convs,          \* 会話（conversation）の有限集合
  Users,          \* 利用者（user）の有限集合
  MaxSeq          \* TLC における探索の上界（例：3 または 4）

ASSUME Convs # {} /\ Users # {} /\ MaxSeq \in Nat

(****************************************************************
 状態（State）
****************************************************************)
VARIABLES
  nextSeq,        \* [c \in Convs -> Nat] : 次に割当てる seq
  Log,            \* メッセージ集合：各要素は [conv, seq, to] を持つレコード
  Inbox,          \* [u \in Users -> SUBSET Log] : 配送済み（ただし未表示を含む）集合
  Displayed       \* [u \in Users -> SUBSET Log] : 表示済み集合

Msg(m) ==
  m \in [conv: Convs, seq: 0..MaxSeq, to: Users]

(****************************************************************
 初期条件（Init）
****************************************************************)
Init ==
  /\ nextSeq \in [Convs -> 0..MaxSeq]
  /\ \A c \in Convs: nextSeq[c] = 0
  /\ Log = {}
  /\ Inbox \in [Users -> SUBSET Log]
  /\ \A u \in Users: Inbox[u] = {}
  /\ Displayed \in [Users -> SUBSET Log]
  /\ \A u \in Users: Displayed[u] = {}

(****************************************************************
 行為（Actions）
****************************************************************)

(*
  Ingress（送信受付）：
  会話 c に対して seq を割当て、メッセージを Log に追加する。
  受信者の選択は任意の u としてモデル化する。
*)
Send(c, u) ==
  /\ c \in Convs /\ u \in Users
  /\ nextSeq[c] < MaxSeq
  /\ LET s == nextSeq[c]
     IN /\ Log' = Log \cup { [conv |-> c, seq |-> s, to |-> u] }
        /\ nextSeq' = [nextSeq EXCEPT ![c] = @ + 1]
  /\ UNCHANGED <<Inbox, Displayed>>

(*
  Delivery（配送）：
  既に Log に記録されているメッセージを、その宛先へ配送する。
  「少なくとも 1 回」配送（at-least-once）をモデル化するため、同一メッセージの再配送を許す。
  ただし Inbox は集合であるため、重複配送は集合上の重複としては消去される。
*)
Deliver(m) ==
  /\ m \in Log
  /\ Inbox' = [Inbox EXCEPT ![m.to] = @ \cup {m}]
  /\ UNCHANGED <<nextSeq, Log, Displayed>>

(*
  Client 表示：
  利用者 u は Inbox[u] から任意のメッセージを選択して表示し得る。
  ただし、会話単位の seq 昇順性を破壊しない場合に限る。
  具体的には、同一会話に関して、表示対象 m の seq は既表示の全ての seq より大きいことを要求する。
*)
CanDisplay(u, m) ==
  /\ u \in Users
  /\ m \in Inbox[u]
  /\ \A d \in Displayed[u]:
        d.conv = m.conv => d.seq < m.seq

Display(u, m) ==
  /\ CanDisplay(u, m)
  /\ Displayed' = [Displayed EXCEPT ![u] = @ \cup {m}]
  /\ UNCHANGED <<nextSeq, Log, Inbox>>

Next ==
  \E c \in Convs, u \in Users: Send(c, u)
  \/ \E m \in Log: Deliver(m)
  \/ \E u2 \in Users: \E m2 \in Inbox[u2]: Display(u2, m2)

(****************************************************************
 不変条件（Invariants；安全性性質）
****************************************************************)

(*
  I1: 会話内 seq の一意性：
  異なる 2 メッセージが同一の (conv, seq) を共有しない。
*)
SeqUnique ==
  \A m1 \in Log:
    \A m2 \in Log:
      (m1.conv = m2.conv /\ m1.seq = m2.seq) => m1 = m2

(*
  I2: nextSeq の単調性：
  各会話について nextSeq は、これまでに割当済みの seq の個数（上界内）に等しく、
  従って減少しない。
  （本モデルでは、集合としての一意性と nextSeq による割当方式により、この性質が誘導される。）
*)
AllocatedSeqs(c) ==
  { m.seq : m \in { x \in Log : x.conv = c } }

NextSeqMatchesAllocated ==
  \A c \in Convs: nextSeq[c] = Cardinality(AllocatedSeqs(c))

(*
  I3: 配送済みおよび表示済みのメッセージは、必ず Log に記録済みである。
*)
InboxFromLog ==
  \A u \in Users: Inbox[u] \subseteq Log

DisplayedFromInboxFromLog ==
  \A u \in Users: Displayed[u] \subseteq Inbox[u] /\ Displayed[u] \subseteq Log

(*
  I4: 会話単位の表示順序（利用者ごと）：
  表示済み集合内で、同一会話の 2 メッセージが seq の順序違反を起こさない。
  （集合としての性質：同一会話内で seq が互いに異なり、いずれかが他方より小さい。）
*)
DisplayedIncreasing ==
  \A u \in Users:
    \A m1 \in Displayed[u]:
      \A m2 \in Displayed[u]:
        (m1.conv = m2.conv /\ m1 # m2) =>
          (m1.seq # m2.seq /\ (m1.seq < m2.seq \/ m2.seq < m1.seq))

(*
  より強い性質（「表示が順序通りである」により近い）：
  任意の u と会話 c に対し、表示済み seq は初期区間 {0..k-1} を成す。
  これは配送が最終的に全メッセージをもたらす等の進行性仮定が必要であり、
  さらに Display に連続性（contiguity）制約を課さない限り、安全性のみとしては一般に主張できない。
  本モデルでは当該制約を仮定しない。
*)

Inv ==
  SeqUnique
  /\ NextSeqMatchesAllocated
  /\ InboxFromLog
  /\ DisplayedFromInboxFromLog
  /\ \A u \in Users:
       \A d \in Displayed[u]:
         \A e \in Displayed[u]:
           (d.conv = e.conv /\ d.seq = e.seq) => d = e
  /\ \A u2 \in Users:
       \A m \in Inbox[u2]:
         Msg(m)

(****************************************************************
 仕様（Spec）
****************************************************************)
Spec ==
  Init /\ [][Next]_<<nextSeq, Log, Inbox, Displayed>>

THEOREM Spec => []Inv


====
\* 変更履歴（Modification History）
\* 最終更新: 2026-02-09 21:37:08 JST（miurayu）
\* 作成:     2026-02-09 21:28:49 JST（miurayu）
