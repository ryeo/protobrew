Meteor.publish('entries', (context) ->

    # Todo: Temporary
    return Entries.find({})

    # Todo: Use when Meteor gets aggregates
    user = Meteor.users.findOne({_id: this.userId}) if this.userId

    # Admins see all!
    if user && user.group == "admin"
        return Entries.find({})

    conditions = [{$ne: ["$entry.mode", "private"]}]

    if user
        conditions.push( {$eq: ["$entry.context": user.profile.username] } ) if user.profile.username
        conditions.push( {$eq: ["$entry.context": user.profile.group] } )    if user.profile.group
    
    visible = {$or: conditions}

    entries = Entries.aggregate
                $project:
                    title: true
                    mode: true
                    context: true
                    tags: {$cond: [visible, "$tags", ""]}
                    text: {$cond: [visible, "$text", ""]}
)


Meteor.publish('tags', -> return Tags.find({}))



Meteor.methods

    updateTitle: (entry, title, callback) ->
        throw new Meteor.Error(403, "You must be logged in") unless this.userId
        return Entries.update( {_id: entry._id}, {$set: {'title': title}} )

    # Todo: lock down fields
    saveEntry: (entry, context, callback) ->
        # Only members can edit
        user = Meteor.user()
        entry = verifySave( entry, user, context )
        entry.context = context

        return Entries.insert(entry, callback) unless entry._id
        return Entries.update({_id: entry._id}, entry, callback)

    updateUser: (value) ->
        throw new Meteor.Error(403, "You must be logged in") unless this.userId

        existing = Meteor.users.find( {"profile.username": value} ).count()
        throw new Meteor.Error(403, "Username exists") if existing > 0

        Meteor.users.update( {_id: this.userId}, {$set: {"profile.username": value}}) if value

    
    createNewPage: () ->
        # ownUnnamedPages = Entries.find( { author : this.userId, title : {$regex: /^unnamed/ }}).sort( { title : 1 } ).fetch # .find(query, projection)
        ownUnnamedPages = Entries.find( { author : this.userId, title : {$regex: /^unnamed/ }}).fetch() # .find(query, projection)
        console.log(ownUnnamedPages)
        if ownUnnamedPages.length == 0
            console.log('1');
            return 'unnamed-1'
        else
            seq = 1
            posted = false
            for pages in ownUnnamedPages
                if ownUnnamedPages[_i].title == 'unnamed-'+seq
                    seq = seq +1
                    console.log('2');
                else
                    console.log('3');
                    return 'unnamed-'+seq
            if ! posted
                seq = seq + 1
                return 'unnamed-'+seq   

    createUserLink: (value) ->

            #   Click New Page button
            #   find all documents in the users namespace with the title "unnamed-*"
            #       entries with user as author 
            #Keep in mind that regex queries can be very expensive as MongoDB will have to run the regex against every single location. If you can anchor your regexes at the beginning:

            #   Users.where('location').$regex(/^unnamed/);
            #       seq = 1

                    #find nearest unnamed page & call new page with that name
                    




                    #         console.log(value);

                    # Meteor.users.update( {_id: this.userId}, {
                    #     $set: {
                    #         profile: {
                    #             userlinks: {
                    #                 owned: value
                    #             }
                    #         }
                    #     }
                    # });


            #       ownPosts = Entries.find({}) 
            #       ownPosts.forEach ->
            #       for titles in entries
            #           if the title == unnamed+seq exists
            #               seq = seq +1
            #           else
            #               newtitle = unnamed+seq
            #               break
            #       if ! newtitle
            #           seq = seq + 1
            #           newtitle = unnamed+seq
            #           
            #   increment through titles starting at 1 until the nearest unnamed is found
            #   create entry with title and url as that in user space
            #   load page in edit mode
            #       if canceled
            #           delete page from records
            #       if navigated away from - warn!
            #       if saved
            #           save entry
            #           save to user profile - created
            #           save to user profile - recent
            #

    #insert if not present - owned links
       # insertNearestField: (doc, targetCollection) ->
            # while 1
            #     Entries.find({})                               
            #     user = Meteor.users({_id: this.userId})                
            #     cursor = user.find( {}, { owned: 1 } ).sort( { _id: 1 } ).limit(1) # .find(query, projection)
            #     seq = cursor.hasNext() ? cursor.next()._id + 1 : 1
            #     owned.unnamed = seq
            #     targetCollection.insert(doc)
            #     err = db.getLastErrorObj()
            #     if err && err.code 
            #         if err.code == 11000 #/* dup key */ 
            #             continue
            #         else
            #             print "unexpected error inserting data: " + tojson( err ) 
            #     break
    


    saveFile: (blob, name, path, encoding) ->
        throw new Meteor.Error(403, "You must be logged in") unless this.userId

        cleanPath = (str) ->
          if str
            str.replace(/\.\./g,'').replace(/\/+/g,'').replace(/^\/+/,'').replace(/\/+$/,'')

        cleanName = (str) ->
          str.replace(/\.\./g,'').replace(/\//g,'')

        path = cleanPath(path)
        fs = __meteor_bootstrap__.require('fs')
        name = cleanName(name || 'file')
        encoding = encoding || 'binary'
        chroot = 'public'

        path = chroot + (if path then '/' + path + '/' else '/')

        path = "public/user-images/#{this.userId}/"

        fs.mkdirSync( path ) if ! fs.existsSync( path )

        fs.writeFile(path + name, blob, encoding, (err) ->
          if err
            console.log( "err" );
          else
            console.log('The file ' + name + ' (' + encoding + ') was saved to ' + path)
        );

        return {filelink: path + name}