# %NOTES:
# %Feval -- evaluate MATLAB command in server
# %GetFullMatrix -- get matrix from server
# %PutFullMatrix -- store matrix in server
# %PutWorkspaceData


# URL mappings
# Home (/)
# Background r'/[0-9a-zA-Z]*/background'
    # (/blink-mod/background)
    # (/psth/background)
# Analysis Input r'/[0-9a-zA-Z]*/analyze'
	# (/blink-mod/analyze)
    # (/psth/analyze)
#Analysis Output r'/[0-9a-zA-Z]*/results'
    # (/blink-mod/results)
    # (/psth/results)
# Code (/get_code)
# Contact (/contact)

from flask import Flask, render_template, request, flash, redirect, url_for
import logging

#conventions for html file naming
def url_to_html(analysis, page):
    if page == 'background':
        return 'background-%s.html' % analysis
    elif page == 'run':
        return 'run-%s.html' % analysis
    elif page == 'results':
        return 'results-%s.html' % analysis


#TODO: put in config file?
DEBUG = True
SECRET_KEY = 'development key'
USERNAME = 'admin'
PASSWORD = 'default'

# create the app 
app = Flask(__name__)
app.config.from_object(__name__) #TODO - change to from_envar


@app.route('/', methods = ['GET'])
def home_page():
    return render_template('home.html')

@app.route('/<analysis>/background', methods = ['GET'])
def background(analysis):
    return render_template(url_to_html(analysis,'background'))

#TODO - this will need the most work
@app.route('/<analysis>/analyze', methods = ['GET', 'POST'])
def run_analysis(analysis):
    if request.method == 'POST':
        flash('Successfully input data')
        logging.debug(request.form['blinks'])
        return redirect('/%s/results' % analysis)
    else:
        return render_template(url_to_html(analysis,'run'))

@app.route('/<analysis>/results', methods = ['GET'])
def results(analysis):
    return render_template(url_to_html(analysis,'results'))

@app.route('/code', methods = ['GET'])  
def get_code():
    return render_template('getcode.html')

@app.route('/contact', methods = ['GET'])  
def contact_us():
    return render_template('contact.html')

if __name__ == '__main__':
    app.run()