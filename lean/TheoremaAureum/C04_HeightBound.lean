import TheoremaAureum.C03_Arakelov
import TheoremaAureum.RHStatement

namespace TheoremaAureum

/-- H2: Weil Positivity Transfer. Hypothesis 2 from your paper.
"If VALOR > 0, then GRH holds for L(s,E)" -/
axiom H2_WeilTransfer : H1_ArakelovPositivity → GRH_E_143a1

end TheoremaAureum
