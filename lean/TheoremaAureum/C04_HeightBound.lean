import TheoremaAureum.C01_Arakelov
import TheoremaAureum.C03_Positivity
import TheoremaAureum.RHStatement

namespace TheoremaAureum

open C03_Positivity

/-- H2: Weil Positivity Transfer.
"If VALOR > 0, then GRH holds for L(s,E)" -/
axiom H2_WeilTransfer : 0 < VALOR → GRH_E_143a1

end TheoremaAureum
