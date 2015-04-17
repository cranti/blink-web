#TODO:
# - Database stuff (remove it)
# - deployment
#
# - fix image links in the html docs

# - should i use trailing slash for url definitions or not?

# URL mappings
# Home (/)
# Background '/<analysis>/background'
# Analysis Input '/<anaysis>/analyze'
# Analysis Output '/<analysis>/results'
# Code (/code)
# Contact (/contact)

#for database:
import sqlite3
from flask import g
from contextlib import closing 


from flask import Flask, render_template, request, redirect, url_for


# import plot1

# create the app 
app = Flask(__name__)
app.config.from_object('config.DevelopmentConfig') #TODO - check
app.config.from_envvar('BLINKWEB_SETTINGS', silent = True) #won't complain if this isn't set...

### utils

#conventions for html file naming
def url_to_html(analysis, page):
    if page == 'background':
        return 'background-%s.html' % analysis
    elif page == 'howto':
        return 'howto-%s.html' % analysis
    elif page == 'methods':
        return 'methods-%s.html' % analysis
    else:
        return '%s-%s.html' % (page, analysis)



### db - TODO: look at this/edit (pulled from flask tutorial)
def connect_db():
    return sqlite3.connect(app.config['DATABASE'])

#helper function to create database (see flaskr)
def init_db():
    with closing(connect_db()) as db:
        with app.open_resource('schema.sql', mode='r') as f:
            db.cursor().executescript(f.read())
        db.commit()

# call before a request, passed no arguments
@app.before_request
def before_request():
    g.db = connect_db()

# call after request
@app.teardown_request
def teardown_request(exception):
    db = getattr(g, 'db', None)
    if db is not None:
        db.close()

#add new entry

#status update (query w/ tracking number)

#get results (including original data)


####

@app.route('/', methods = ['GET'])
def home_page():
    return render_template('home.html')

@app.route('/<analysis>/background/', methods = ['GET'])
def background(analysis):
    return render_template(url_to_html(analysis,'background'))

@app.route('/<analysis>/', methods = ['GET'])
def baseanalysis(analysis):
    return redirect('/%s/background' % analysis)

@app.route('/<analysis>/howto/', methods = ['GET'])
def howto(analysis):
    return render_template(url_to_html(analysis,'howto'))

@app.route('/<analysis>/methods/', methods = ['GET'])
def results(analysis):
    return render_template(url_to_html(analysis,'methods'))

@app.route('/install/', methods = ['GET'])  
def get_code():
    return render_template('install.html')

@app.route('/contact', methods = ['GET'])  
def contact_us():
    return render_template('contact.html')

if __name__ == '__main__':
    app.run()