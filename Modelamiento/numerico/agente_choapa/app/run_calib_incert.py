import pandas as pd
import numpy as np
import os
import shutil

# Current directory
cwd = os.getcwd()

# Correr modelos calibrados
for run in np.arange(1, 21):
    # Abrir archivo de parámetros
    params =pd.read_csv(os.path.join(cwd, 'params', 'param{}.par'.format(run)), sep=r'\s+', skiprows=1, header=None)
    params.columns=['parameter', 'value', 'aux1', 'aux2']
    
    # Separar por parámetro
    kx_values = params.loc[params.parameter.str.contains('kx')].copy()
    ss_values = params.loc[params.parameter.str.contains('ss')].copy()
    sy_values = params.loc[params.parameter.str.contains('sy')].copy()
    vani_values = params.loc[params.parameter.str.contains('vani')].copy()
    po_values = params.loc[params.parameter.str.contains('po')].copy()
    
    # Reemplazar los parámetros hidráulicos en archivos de puntos piloto
    for layer in range(3):
        kx_tpl = pd.read_csv(os.path.join('model', 'kx_{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        kx_tpl = kx_tpl[[1]]
        kx_tpl = pd.merge(left=kx_tpl, right=kx_values, how='left', left_on=[1], right_on='parameter')
        kx_tpl[1] = kx_tpl['value']
        kx_tpl = kx_tpl[[1]]
        kx_tpl.to_csv(os.path.join('model', 'kx_{}.dat'.format(layer+1)), sep='\t', header=None, index=False)
        ss_tpl = pd.read_csv(os.path.join('model', 'ss_{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        ss_tpl = ss_tpl[[1]]
        ss_tpl = pd.merge(left=ss_tpl, right=ss_values, how='left', left_on=[1], right_on='parameter')
        ss_tpl[1] = ss_tpl['value']
        ss_tpl = ss_tpl[[1]]
        ss_tpl.to_csv(os.path.join('model', 'ss_{}.dat'.format(layer+1)), sep='\t', header=None, index=False)
        sy_tpl = pd.read_csv(os.path.join('model', 'sy_{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        sy_tpl = sy_tpl[[1]]
        sy_tpl = pd.merge(left=sy_tpl, right=sy_values, how='left', left_on=[1], right_on='parameter')
        sy_tpl[1] = sy_tpl['value']
        sy_tpl = sy_tpl[[1]]
        sy_tpl.to_csv(os.path.join('model', 'sy_{}.dat'.format(layer+1)), sep='\t', header=None, index=False)
        vani_tpl = pd.read_csv(os.path.join('model', 'vani_{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        vani_tpl = vani_tpl[[1]]
        vani_tpl = pd.merge(left=vani_tpl, right=vani_values, how='left', left_on=[1], right_on='parameter')
        vani_tpl[1] = vani_tpl['value']
        vani_tpl = vani_tpl[[1]]
        vani_tpl.to_csv(os.path.join('model', 'vani_{}.dat'.format(layer+1)), sep='\t', header=None, index=False)
        po_tpl = pd.read_csv(os.path.join('model', 'po_{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        po_tpl = po_tpl[[1]]
        po_tpl = pd.merge(left=po_tpl, right=po_values, how='left', left_on=[1], right_on='parameter')
        po_tpl[1] = po_tpl['value']
        po_tpl = po_tpl[[1]]
        po_tpl.to_csv(os.path.join('model', 'po_{}.dat'.format(layer+1)), sep='\t', header=None, index=False)
    
    # Correr modelos
    os.chdir('model')
    os.system('00_Run.bat')
    
    # Extraer resultados
    os.system('00_Results.bat')
    os.chdir(cwd)
    
    # Copiar archivos de resultados
    shutil.copy(os.path.join(cwd, 'model', 'niv_sim.smp'), os.path.join(cwd, 'resultados', 'niv_sim_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'niv_sim.mod2obs'), os.path.join(cwd, 'resultados', 'niv_sim_{}.mod2obs'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc_sim.smp'), os.path.join(cwd, 'resultados', 'conc_sim_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc_sim.mod2obs'), os.path.join(cwd, 'resultados', 'conc_sim_{}.mod2obs'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'heads.dat'), os.path.join(cwd, 'resultados', 'heads_{}.dat'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc.dat'), os.path.join(cwd, 'resultados', 'conc_{}.dat'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'balance_all.2.csv'), os.path.join(cwd, 'resultados', 'balance_all_{}.csv'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'balance_zonas.2.csv'), os.path.join(cwd, 'resultados', 'balance_zonas_{}.csv'.format(run)))
