import pandas as pd
import numpy as np
import os
import shutil

# Current directory
cwd = os.getcwd()

# Correr modelos calibrados
for run in np.arange(1, 2):
    # Abrir archivo de parámetros
    params =pd.read_csv(os.path.join(cwd, 'params', 'par{}.par'.format(run)), sep=r'\s+', skiprows=1, header=None)
    params.columns=['parameter', 'value', 'aux1', 'aux2']
    
    # Separar por parámetro
    kx_values = params.loc[params.parameter.str.contains('kx')].copy()
    ss_values = params.loc[params.parameter.str.contains('ss')].copy()
    sy_values = params.loc[params.parameter.str.contains('sy')].copy()
    vani_values = params.loc[params.parameter.str.contains('hani')].copy()
    po_values = params.loc[params.parameter.str.contains('por')].copy()
    
    # Reemplazar los parámetros hidráulicos en archivos de puntos piloto
    for layer in range(6):
        kx_tpl = pd.read_csv(os.path.join('model', 'Kx{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        kx_tpl = kx_tpl[[1]]
        kx_tpl[1] = kx_tpl[1].str.lower()
        kx_tpl = pd.merge(left=kx_tpl, right=kx_values, how='left', left_on=[1], right_on='parameter')
        kx_tpl[1] = kx_tpl['value']
        kx_tpl = kx_tpl[[1]]
        kx_tpl.to_csv(os.path.join('model', 'MLP_TS_mar22{}._kx'.format(layer+1)), sep='\t', header=None, index=False)
        ss_tpl = pd.read_csv(os.path.join('model', 'Ss{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        ss_tpl = ss_tpl[[1]]
        ss_tpl[1] = ss_tpl[1].str.lower()
        ss_tpl = pd.merge(left=ss_tpl, right=ss_values, how='left', left_on=[1], right_on='parameter')
        ss_tpl[1] = ss_tpl['value']
        ss_tpl = ss_tpl[[1]]
        ss_tpl.to_csv(os.path.join('model', 'MLP_TS_mar22{}._s1'.format(layer+1)), sep='\t', header=None, index=False)
        sy_tpl = pd.read_csv(os.path.join('model', 'Sy{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        sy_tpl = sy_tpl[[1]]
        sy_tpl[1] = sy_tpl[1].str.lower()
        sy_tpl = pd.merge(left=sy_tpl, right=sy_values, how='left', left_on=[1], right_on='parameter')
        sy_tpl[1] = sy_tpl['value']
        sy_tpl = sy_tpl[[1]]
        sy_tpl.to_csv(os.path.join('model', 'MLP_TS_mar22{}._s2'.format(layer+1)), sep='\t', header=None, index=False)
        vani_tpl = pd.read_csv(os.path.join('model', 'Hani{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        vani_tpl = vani_tpl[[1]]
        vani_tpl[1] = vani_tpl[1].str.lower()
        vani_tpl = pd.merge(left=vani_tpl, right=vani_values, how='left', left_on=[1], right_on='parameter')
        vani_tpl[1] = vani_tpl['value']
        vani_tpl = vani_tpl[[1]]
        vani_tpl.to_csv(os.path.join('model', 'MLP_TS_mar22{}._kz'.format(layer+1)), sep='\t', header=None, index=False)
        po_tpl = pd.read_csv(os.path.join('model', 'Por{}.tpl'.format(layer+1)), sep=r'\s+', header=None, skiprows=1)
        po_tpl = po_tpl[[1]]
        po_tpl[1] = po_tpl[1].str.lower()
        po_tpl = pd.merge(left=po_tpl, right=po_values, how='left', left_on=[1], right_on='parameter')
        po_tpl[1] = po_tpl['value']
        po_tpl = po_tpl[[1]]
        po_tpl.to_csv(os.path.join('model', 'MLP_TS_mar22{}._po'.format(layer+1)), sep='\t', header=None, index=False)
    
    # Correr modelo y sacar resultados
    os.chdir('model')
    os.system('0_runmodel.bat')
    os.chdir(cwd)
    
    # Copiar archivos de resultados
    shutil.copy(os.path.join(cwd, 'model', 'niv_sim_rms.smp'), os.path.join(cwd, 'resultados', 'niv_sim_rms_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc_sim_rms.smp'), os.path.join(cwd, 'resultados', 'conc_sim_rms_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'head_ts_CV.smp'), os.path.join(cwd, 'resultados', 'head_ts_CV_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'head_ts_PA.smp'), os.path.join(cwd, 'resultados', 'head_ts_PA_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc_ts.smp'), os.path.join(cwd, 'resultados', 'conc_ts_{}.smp'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'head_31-12-2023.dat'), os.path.join(cwd, 'resultados', 'head_31-12-2023_{}.dat'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'conc_31-12-2023.dat'), os.path.join(cwd, 'resultados', 'conc_31-12-2023_{}.dat'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'balance.2.csv'), os.path.join(cwd, 'resultados', 'balance_{}.csv'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'flujo_pasante.2.csv'), os.path.join(cwd, 'resultados', 'flujo_pasante_{}.csv'.format(run)))
    shutil.copy(os.path.join(cwd, 'model', 'Vol_almac.2.csv'), os.path.join(cwd, 'resultados', 'Vol_almac_{}.csv'.format(run)))
