import pandas as pd
import numpy as np
import os
import shutil
import subprocess
from time import sleep
from datetime import datetime

def main():
    print("Starting MODFLOW simulation...")
    start = datetime.now()
    print(start.strftime("%Y-%m-%d %H:%M:%S"))
    print(os.getenv('ID_PARAMETRO', 0))
    run = int(os.getenv('ID_PARAMETRO', 0))  # Get the run number from environment variable

    if run == 0:
        print("ID_PARAMETRO no asignado, no se ejecuta el modelo.")
        return

    # Current directory
    cwd = os.getcwd()
    print(f"cwd: {cwd}")

    #validar si existe el archivo de parámetros
    if not os.path.isfile(os.path.join(cwd, 'params', 'param{}.par'.format(run))):
        print("El archivo NO existe.")
        return

    # Here you would set up the model, run simulations, and process results.
    # This is a placeholder for the actual implementation.

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
    #os.system('00_Run.bat')
    print("COMIENZA EJECUCIÓN USGs_1.exe.....")
    start1 = datetime.now()
    print(start1.strftime("%Y-%m-%d %H:%M:%S"))
    # Ejecuta el modelo USG
    resultado = subprocess.run('wine USGs_1.exe choapa_1.nam', shell=True, capture_output=True, text=True)
    print("FIN EJECUCIÓN USGs_1.exe.....")
    end1 = datetime.now()
    print(end1.strftime("%Y-%m-%d %H:%M:%S"))
    print("tiempo transcurrido USGs_1.exe:", end1-start1)
    print(resultado)
    
    # Extraer resultados
    print("resultados usgmod2smp_niv:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine usgmod2smp.exe < usgmod2smp_niv.in', shell=True, capture_output=True, text=True)
    print("resultados usgmod2smp_con:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine usgmod2smp.exe < usgmod2smp_con.in', shell=True, capture_output=True, text=True)
    print("resultados usgmod2obs_niv:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine usgmod2obs.exe < usgmod2obs_niv.in', shell=True, capture_output=True, text=True)
    print("resultados smp2smp_con:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine smp2smp.exe < smp2smp_con.in', shell=True, capture_output=True, text=True)
    print("resultados usgbin2tab_heads:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine usgbin2tab_h.exe < usgbin2tab_heads.in', shell=True, capture_output=True, text=True)
    print("resultados usgbin2tab_conc:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine usgbin2tab_h.exe < usgbin2tab_conc.in', shell=True, capture_output=True, text=True)
    print("resultados zonbudusg_all:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine zonbudusg.exe < zonbudusg_all.in', shell=True, capture_output=True, text=True)
    print("resultados zonbudusg_zonas:", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    resultado = subprocess.run('wine zonbudusg.exe < zonbudusg_zonas.in', shell=True, capture_output=True, text=True)
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

    end = datetime.now()
    print("Simulation completed, parameter:", run)
    print(end.strftime("%Y-%m-%d %H:%M:%S"))
    print("Total time taken:", end - start)

if __name__ == "__main__":
    main()