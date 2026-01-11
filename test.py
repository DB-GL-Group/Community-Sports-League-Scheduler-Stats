
def get_finalists(allTeamIDs):
    nbrWinsPerTeam = {}
    for i in allTeamIDs:
        nbrWinsPerTeam.update({i : 0})
    return nbrWinsPerTeam

print(get_finalists([1,2,3]))
        
        