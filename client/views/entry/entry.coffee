root = exports ? this

# Recursively build tree of headings starting with the first one provided
#
# Example Return Value
# [{
#   "title": "title",
#   "id": 0,
#   "target": "entry-heading-0",
#   "style": "top",
#   "children": [
#     {...},
#     {...}
#   ]
# }]
#
@buildHeadingTree = (items, cur=1, counter=1) ->
    next = cur + 1
    nodes = []
    for elem, index in items
        $elem = $(elem)
        children = onlyNonEmpty($elem.nextUntil('h' + cur, 'h' + next))
        d = {}
        d.title = $elem.text()
        d.id = counter++
        d.target = "entry-heading-#{d.id}"
        d.style = "top" if cur == 0
        d.children = buildHeadingTree(children, next, counter) if children.length > 0
        nodes.push(d)
    return nodes

# Given a collection of headlines, return only those that include
# non-whitespace characters
@onlyNonEmpty = ($hs) ->
    _.filter $hs, (h) ->
      $(h).text().match(/[^\s]/) #matches any non-whitespace char


Template.entry.title = ->
    Session.get('title')

Template.entry.titleHidden = ->
    Session.get('titleHidden')

Template.entry.entryLoaded = ->
    Session.get('entryLoaded')

Template.entry.userContext = ->
    Session.get('context')

Template.entry.lastEditedBy = ->
    title = Session.get('title')
    context = Session.get('context')
    entry = findSingleEntryByTitle( title, context )
    UserLib.lastEditedBy(entry)

Template.entry.sinceLastEdit = ->
    title = Session.get('title')
    context = Session.get('context')
    entry = findSingleEntryByTitle( title, context )
    UserLib.sinceLastEdit(entry)

Template.entry.entry = ->
    title = Session.get('title')
    context = Session.get('context')
    if title
        entry = findSingleEntryByTitle( title, context )

        if entry
            Session.set('entry', entry )
            Session.set('entryId', entry._id )

            source = $('<div>').html( entry.text ) #make a div with entry.text as the innerHTML
            headings = buildHeadingTree( onlyNonEmpty( source.find(":header:first")) )
            headings.unshift( {id: 0, target: "article-title", title: Session.get('title') } )
            if headings.length > 0
                for e, i in source.find('h1,h2,h3,h4,h5')
                    e.id = "entry-heading-" + (i + 1)

            entry.text = source.html()
            entry
        else
            Session.set( 'entry', {} )
            Session.set( 'entryId', null )
            Session.get('entryLoaded')

Template.entry.events

    'click a.entry-link': (evt) ->
        if Session.get('editMode')
            evt.preventDefault()
        else
            evtNavigate(evt)

    # for Create It! button on new page
    'click .edit': (evt) ->
        Session.set( 'y-offset', window.pageYOffset )
        evt.preventDefault()
        lockEntry()
        Session.set('editMode', true)

    'click #article-title': (evt) ->

        entry = Session.get('entry')
        context = Session.get("context")
        user  = Meteor.user()
        return unless editable( entry, user, context )

        $el = $(evt.target)
        $in = $("<input class='entry-title-input'/>")
        $in.val( $el.text().trim() )
        $el.replaceWith($in)
        $in.focus()

        updateTitle = (e, force = false) ->
            if force || e.target != $el[0] && e.target != $in[0]
                if $in.val() != $el.text()
                    Meteor.call 'updateTitle', Session.get('entry'), Session.get('context'), $in.val(), (error, result) ->
                        if error
                            Toast.error('Page already exists!')
                        else
                            $el.html($in.val())
                            navigate($in.val())

                $in.replaceWith($el)
                $(document).off('click')

        cancel = (e, force = false) ->
            if force || e.target != $el[0] && e.target != $in[0]
                $in.replaceWith($el)
                $(document).off('click')

        $(document).on('click', updateTitle)

        $in.on("keyup", (e) ->
            updateTitle(e, true) if e.keyCode == 13
            cancel(e, true) if e.keyCode == 27
        )


Template.editEntry.rendered = ->
    el = $( '#entry-text' )

    window.EntryLib.initRedactor( el, ['autoSuggest', 'stickyScrollToolbar'] )

    window.scrollTo(0,Session.get('y-offset'))

    minHeight = $(window).height() - 190 #   top toolbar = 50px,  title = 90px wmargin,  redactor toolbar = 30 px,  bottom margin = 20px
    if( $('.redactor_').height() < minHeight )
        $('.redactor_').css('min-height', minHeight)

    tags = Tags.find({})
    entry = Session.get('entry')

    $('#entry-tags').textext({
        plugins : 'autocomplete suggestions tags',
        tagsItems: if entry then entry.tags else []
        suggestions: tags.map (t) -> t.name
    });


deleteEntry = (evt) ->
    entry = Session.get('entry')
    if entry
        Meteor.call('deleteEntry',entry)
        Entries.remove({_id: entry._id})
        Session.set('editMode', false)
        Session.set('editEntry', false)
    else
        Toast.error('Cannot DELETE a page that has not been created!')

@saveEntry = (evt) ->
    reroute = ( e ) ->
        navigate( '/'+entry.title, Session.get( "context" ) ) unless entry.title == "home"

    title = Session.get('title')

    entry = {
        'title': title
        'text': rewriteLinks( $('#entry-text').val() )
        'mode': $('#mode').val()
    }

    tags = $('#entry-tags').nextAll('input[type=hidden]').val()

    if tags
        tags = JSON.parse(tags)
        entry.tags = tags;
        Tags.insert({'name':tag}) for tag in tags

    eid = Session.get('entryId')
    entry._id = eid if eid

    context = Session.get('context')
    # TODO should call verifySave from here and the server saveEntry function
    # rather than just the server saveEntry function?

    # Meteor.call('saveEntry', title, entry, context, reroute)
    Meteor.call('saveEntry', title, entry, context)
    Entries.update({_id: entry._id}, entry)
    Session.set("editMode", false)
