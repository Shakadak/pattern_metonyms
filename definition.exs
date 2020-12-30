Guarded Remote View   : ((dot_call -> pat) when guard) -> expr
Guarded Local  View   : ((call     -> pat) when guard) -> expr
Guarded Remote Syn    : ( dot_call         when guard) -> expr
Guarded Local  Syn    : ( call             when guard) -> expr
Guarded        Clause : (             pat  when guard) -> expr
        Remote View   : ((dot_call -> pat)           ) -> expr
        Local  View   : ((call     -> pat)           ) -> expr
        Remote Syn    : ( dot_call                   ) -> expr
        Local  Syn    : ( call                       ) -> expr
               Clause : (             pat            ) -> expr

# Can't distinguish yet between irrefutable pattern and synonym
when Syn do expansion until not Syn

# Target
# can be directly used by view
Guarded Remote View   : ((dot_call -> pat) when guard) -> expr
Guarded Local  View   : ((call     -> pat) when guard) -> expr
Guarded        Clause : (             pat  when guard) -> expr
        Remote View   : ((dot_call -> pat)           ) -> expr
        Local  View   : ((call     -> pat)           ) -> expr
               Clause : (             pat            ) -> expr
# Adapt so non guarded can be used as if guarded
# So handle only
Guarded Remote View   : ((dot_call -> pat) when guard) -> expr
Guarded Local  View   : ((call     -> pat) when guard) -> expr
Guarded        Clause : (             pat  when guard) -> expr
